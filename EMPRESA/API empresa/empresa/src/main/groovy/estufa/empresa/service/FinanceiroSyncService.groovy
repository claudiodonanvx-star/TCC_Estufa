package estufa.empresa.service

import estufa.empresa.model.StatusFinanceiro
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.boot.context.event.ApplicationReadyEvent
import org.springframework.context.event.EventListener
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

import java.nio.charset.StandardCharsets
import java.sql.Timestamp
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.concurrent.atomic.AtomicBoolean

@Service
@ConditionalOnProperty(name = "empresa.financeiro.sync.enabled", havingValue = "true", matchIfMissing = true)
class FinanceiroSyncService {

    private static final Logger log = LoggerFactory.getLogger(FinanceiroSyncService)
    private static final int DIA_VENCIMENTO = 10
    private static final int DIAS_REGRA_BFP = 5
    private static final byte[] SIMULATED_PDF_BYTES = (
            "%PDF-1.4\n% Simulacao de boleto\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n"
    ).getBytes(StandardCharsets.UTF_8)

    private final JdbcTemplate jdbcTemplate
    private final AtomicBoolean emExecucao = new AtomicBoolean(false)

    FinanceiroSyncService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate
    }

    @EventListener(ApplicationReadyEvent)
    void sincronizarNoStartup() {
        sincronizarFinanceiro("startup")
    }

    @Scheduled(cron = '${empresa.financeiro.sync.cron:0 0 1 * * *}')
    void sincronizarAgendado() {
        sincronizarFinanceiro("agendado")
    }

    @Transactional
    void sincronizarFinanceiro(String origem = "manual") {
        if (!emExecucao.compareAndSet(false, true)) {
            log.info("Sincronizacao financeira ignorada; execucao anterior ainda em andamento ({})", origem)
            return
        }

        try {
            garantirSchemaFinanceiro()
            gerarBoletosFaltantes()
            atualizarStatusFinanceiroUnidades()
            log.info("Sincronizacao financeira concluida com sucesso ({})", origem)
        } catch (Exception exception) {
            log.error("Falha ao sincronizar financeiro da empresa ({})", origem, exception)
            throw exception
        } finally {
            emExecucao.set(false)
        }
    }

    private void garantirSchemaFinanceiro() {
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS emp_boletos (
                id BIGINT(20) NOT NULL AUTO_INCREMENT,
                unidade_id BIGINT(20) NOT NULL,
                competencia DATE NOT NULL,
                vencimento DATE NOT NULL,
                valor DECIMAL(12,2) NOT NULL DEFAULT 0.00,
                pago_em DATE DEFAULT NULL,
                status_boleto ENUM('PENDENTE', 'PAGO') NOT NULL DEFAULT 'PENDENTE',
                arquivo_pdf LONGBLOB DEFAULT NULL,
                nome_arquivo VARCHAR(160) DEFAULT NULL,
                criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (id),
                UNIQUE KEY uk_emp_boletos_unidade_competencia (unidade_id, competencia),
                KEY idx_emp_boletos_vencimento (vencimento),
                CONSTRAINT fk_emp_boletos_unidade FOREIGN KEY (unidade_id) REFERENCES emp_unidades (id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)

        if (!colunaExiste("emp_unidades", "status_financeiro")) {
            jdbcTemplate.execute("""
                ALTER TABLE emp_unidades
                ADD COLUMN status_financeiro ENUM('ATIVO', 'CANCELADO', 'BFP')
                NOT NULL DEFAULT 'ATIVO'
                AFTER ativa
            """)
        }
    }

    private boolean colunaExiste(String tabela, String coluna) {
        Integer total = jdbcTemplate.queryForObject(
                """
                    SELECT COUNT(*)
                    FROM information_schema.columns
                    WHERE table_schema = DATABASE()
                      AND table_name = ?
                      AND column_name = ?
                """,
                Integer,
                tabela,
                coluna
        )
        return (total ?: 0) > 0
    }

    private void gerarBoletosFaltantes() {
        List<Map<String, Object>> unidades = jdbcTemplate.queryForList("""
            SELECT
                u.id,
                u.criado_em,
                u.quantidade_estufas,
                MIN(c.inicio_em) AS inicio_contrato
            FROM emp_unidades u
            LEFT JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id AND cu.ativo = 1
            LEFT JOIN emp_contratos c ON c.id = cu.contrato_id
            GROUP BY u.id, u.criado_em, u.quantidade_estufas
            ORDER BY u.id ASC
        """)

        LocalDate mesAtual = LocalDate.now().withDayOfMonth(1)

        unidades.each { unidade ->
            Long unidadeId = ((Number) unidade.id).longValue()
            int quantidadeEstufas = ((Number) (unidade.quantidade_estufas ?: 1)).intValue()
            LocalDate competenciaInicial = resolverMesInicial(unidade)

            iterarMeses(competenciaInicial, mesAtual).each { competencia ->
                LocalDate vencimento = competencia.withDayOfMonth(DIA_VENCIMENTO)
                LocalDate pagoEm = simularDataPagamento(unidadeId, competencia, vencimento)
                String statusBoleto = pagoEm == null ? "PENDENTE" : "PAGO"
                BigDecimal valor = calcularValor(quantidadeEstufas)
                String nomeArquivo = "boleto_unidade_${unidadeId}_${competencia.year}_${String.format('%02d', competencia.monthValue)}.pdf"

                jdbcTemplate.update(
                        """
                            INSERT INTO emp_boletos (
                                unidade_id,
                                competencia,
                                vencimento,
                                valor,
                                pago_em,
                                status_boleto,
                                arquivo_pdf,
                                nome_arquivo
                            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                            ON DUPLICATE KEY UPDATE id = id
                        """,
                        unidadeId,
                        java.sql.Date.valueOf(competencia),
                        java.sql.Date.valueOf(vencimento),
                        valor,
                        pagoEm == null ? null : java.sql.Date.valueOf(pagoEm),
                        statusBoleto,
                        SIMULATED_PDF_BYTES,
                        nomeArquivo
                )
            }
        }
    }

    private LocalDate resolverMesInicial(Map<String, Object> unidade) {
        LocalDate inicioContrato = toLocalDate(unidade.inicio_contrato)
        if (inicioContrato != null) {
            return inicioContrato.withDayOfMonth(1)
        }

        LocalDate criadoEm = toLocalDate(unidade.criado_em)
        if (criadoEm != null) {
            return criadoEm.withDayOfMonth(1)
        }

        return LocalDate.now().withDayOfMonth(1)
    }

    private static LocalDate toLocalDate(Object valor) {
        if (valor == null) {
            return null
        }
        if (valor instanceof LocalDate) {
            return (LocalDate) valor
        }
        if (valor instanceof LocalDateTime) {
            return ((LocalDateTime) valor).toLocalDate()
        }
        if (valor instanceof java.sql.Date) {
            return ((java.sql.Date) valor).toLocalDate()
        }
        if (valor instanceof Timestamp) {
            return ((Timestamp) valor).toLocalDateTime().toLocalDate()
        }
        if (valor instanceof Date) {
            return Instant.ofEpochMilli(((Date) valor).time).atZone(ZoneId.systemDefault()).toLocalDate()
        }
        return LocalDate.parse(valor.toString())
    }

    private static List<LocalDate> iterarMeses(LocalDate inicio, LocalDate fim) {
        List<LocalDate> meses = []
        LocalDate cursor = inicio.withDayOfMonth(1)
        LocalDate limite = fim.withDayOfMonth(1)
        while (!cursor.isAfter(limite)) {
            meses << cursor
            cursor = cursor.plusMonths(1)
        }
        return meses
    }

    private static BigDecimal calcularValor(int quantidadeEstufas) {
        BigDecimal base = new BigDecimal("350.00")
        BigDecimal porEstufa = new BigDecimal("120.00")
        return base.add(porEstufa.multiply(BigDecimal.valueOf(quantidadeEstufas))).setScale(2)
    }

    private static LocalDate simularDataPagamento(Long unidadeId, LocalDate competencia, LocalDate vencimento) {
        LocalDate mesAtual = LocalDate.now().withDayOfMonth(1)
        if (!competencia.isBefore(mesAtual)) {
            return null
        }

        int chave = ((unidadeId * 37) + competencia.monthValue + competencia.year) % 7
        switch (chave) {
            case 0:
            case 1:
                return vencimento.minusDays(1)
            case 2:
                return vencimento.plusDays(3)
            case 3:
                return null
            case 4:
                return vencimento.plusDays(8)
            default:
                return vencimento.plusDays(1)
        }
    }

    private void atualizarStatusFinanceiroUnidades() {
        jdbcTemplate.update("""
            UPDATE emp_unidades u
            LEFT JOIN (
                SELECT
                    unidade_id,
                    MAX(
                        CASE
                            WHEN pago_em IS NULL
                             AND DATE_ADD(vencimento, INTERVAL ${DIAS_REGRA_BFP} DAY) < CURDATE()
                            THEN 1
                            ELSE 0
                        END
                    ) AS has_bfp
                FROM emp_boletos
                GROUP BY unidade_id
            ) b ON b.unidade_id = u.id
            SET u.status_financeiro = CASE
                WHEN IFNULL(u.ativa, 0) = 0 THEN '${StatusFinanceiro.CANCELADO.name()}'
                WHEN IFNULL(b.has_bfp, 0) = 1 THEN '${StatusFinanceiro.BFP.name()}'
                ELSE '${StatusFinanceiro.ATIVO.name()}'
            END
        """)
    }
}