package com.example.apiProjeto.service;

import java.sql.PreparedStatement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ConsultaBancoLeituraService {

    private static final int LIMITE_MAXIMO = 50;
    private static final int LIMITE_EXPORTACAO = 5000;
    private static final int TAMANHO_MAXIMO_TERMO = 100;
    private static final int JANELA_EXPORTACAO_MAXIMA_DIAS = 31;

    private static final Map<String, TabelaConsulta> TABELAS = Map.of(
            "sensor_data", new TabelaConsulta(
                    List.of("id", "coletado_em", "temperatura", "umidade", "umidade_solo", "significado"),
                    List.of("significado"),
                    "coletado_em",
                    "coletado_em",
                    List.of("id")),
            "cultivos", new TabelaConsulta(
                    List.of("id", "nome", "tipo", "temperatura_minima", "temperatura_maxima",
                            "umidade_minima", "umidade_maxima", "umidade_solo_minima",
                            "umidade_solo_maxima", "habilitada"),
                    List.of("nome", "tipo"),
                    "id",
                    null,
                    List.of()),
            "alertas", new TabelaConsulta(
                    List.of("id", "tipo", "severidade", "valor", "limite_min", "limite_max",
                            "mensagem", "gerado_em"),
                    List.of("tipo", "severidade", "mensagem"),
                    "gerado_em",
                    "gerado_em",
                    List.of("id")),
            "relatorio_diario", new TabelaConsulta(
                    List.of("id", "data_ref", "temp_media", "temp_minima", "temp_maxima",
                            "umidade_media", "umidade_minima", "umidade_maxima", "solo_media",
                            "solo_minima", "solo_maxima", "total_leituras", "atualizado_em"),
                    List.of(),
                    "data_ref",
                    "data_ref",
                    List.of()));

    private final JdbcTemplate jdbcTemplate;

    public ConsultaBancoLeituraService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> consultar(String tabelaSolicitada, String termo, int quantidade, String ordem) {
        return consultar(tabelaSolicitada, termo, null, null, quantidade, ordem);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> consultar(
            String tabelaSolicitada,
            String termo,
            LocalDate inicio,
            LocalDate fim,
            int quantidade,
            String ordem) {
        List<Map<String, Object>> linhas = consultarLinhas(
                tabelaSolicitada, termo, inicio, fim, quantidade, ordem, LIMITE_MAXIMO);
        return Map.of(
                "tabela", normalizarTabela(tabelaSolicitada),
                "quantidadeRetornada", linhas.size(),
                "limiteAplicado", Math.max(1, Math.min(LIMITE_MAXIMO, quantidade)),
                "registros", linhas);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> consultarParaExportacao(
            String tabelaSolicitada,
            LocalDate inicio,
            LocalDate fim) {
        if (inicio == null || fim == null) {
            throw new IllegalArgumentException("Informe as datas inicial e final do relatório.");
        }
        if (fim.isBefore(inicio)) {
            throw new IllegalArgumentException("A data final deve ser igual ou posterior à inicial.");
        }
        if (fim.isAfter(inicio.plusDays(JANELA_EXPORTACAO_MAXIMA_DIAS - 1L))) {
            throw new IllegalArgumentException("O intervalo máximo para exportação é de 31 dias.");
        }
        return consultarLinhas(
                tabelaSolicitada, "", inicio, fim, LIMITE_EXPORTACAO, "antigos", LIMITE_EXPORTACAO);
    }

    private List<Map<String, Object>> consultarLinhas(
            String tabelaSolicitada,
            String termo,
            LocalDate inicio,
            LocalDate fim,
            int quantidade,
            String ordem,
            int limiteMaximo) {
        String tabela = normalizarTabela(tabelaSolicitada);
        TabelaConsulta definicao = TABELAS.get(tabela);
        if (definicao == null) {
            throw new IllegalArgumentException("Tabela não permitida para consulta do agente.");
        }
        if ((inicio == null) != (fim == null)) {
            throw new IllegalArgumentException("Informe as datas inicial e final do intervalo.");
        }
        if (inicio != null && fim.isBefore(inicio)) {
            throw new IllegalArgumentException("A data final deve ser igual ou posterior à inicial.");
        }
        if ((inicio != null || fim != null) && definicao.colunaData() == null) {
            throw new IllegalArgumentException("Esta tabela não possui um campo de data para filtrar.");
        }

        String busca = termo == null ? "" : termo.trim();
        if (busca.length() > TAMANHO_MAXIMO_TERMO) {
            throw new IllegalArgumentException("O termo de busca excede o tamanho máximo permitido.");
        }

        int limite = Math.max(1, Math.min(limiteMaximo, quantidade));
        String direcao = "antigos".equalsIgnoreCase(ordem) ? "ASC" : "DESC";
        StringBuilder sql = new StringBuilder("SELECT ")
                .append(String.join(", ", definicao.colunas()))
                .append(" FROM ")
                .append(tabela);
        List<Object> parametros = new ArrayList<>();
        List<String> condicoes = new ArrayList<>();

        if (inicio != null) {
            if (tabela.equals("relatorio_diario")) {
                condicoes.add(definicao.colunaData() + " >= ?");
                parametros.add(inicio);
                condicoes.add(definicao.colunaData() + " <= ?");
                parametros.add(fim);
            } else {
                condicoes.add(definicao.colunaData() + " >= ?");
                parametros.add(inicio.atStartOfDay());
                condicoes.add(definicao.colunaData() + " < ?");
                parametros.add(fim.plusDays(1).atStartOfDay());
            }
        }

        if (!busca.isBlank()) {
            if (tabela.equals("relatorio_diario")) {
                if (!condicoes.isEmpty()) {
                    throw new IllegalArgumentException(
                            "Use o intervalo de datas para filtrar relatórios diários.");
                }
                try {
                    parametros.add(LocalDate.parse(busca));
                } catch (DateTimeParseException erro) {
                    throw new IllegalArgumentException(
                            "Para buscar relatórios, informe a data no formato AAAA-MM-DD.", erro);
                }
                condicoes.add("data_ref = ?");
            } else {
                if (definicao.colunasBusca().isEmpty()) {
                    throw new IllegalArgumentException("Esta tabela não permite busca por texto.");
                }
                condicoes.add("(" + String.join(" OR ", definicao.colunasBusca().stream()
                        .map(coluna -> coluna + " LIKE ?")
                        .toList()) + ")");
                String padrao = "%" + busca + "%";
                definicao.colunasBusca().forEach(coluna -> parametros.add(padrao));
            }
        }

        if (!condicoes.isEmpty()) {
            sql.append(" WHERE ").append(String.join(" AND ", condicoes));
        }
        sql.append(" ORDER BY ")
                .append(definicao.colunaOrdenacao())
                .append(' ')
                .append(direcao);
        for (String coluna : definicao.colunasDesempate()) {
            sql.append(", ").append(coluna).append(' ').append(direcao);
        }
        sql.append(" LIMIT ?");
        parametros.add(limite);

        return jdbcTemplate.query(connection -> {
            connection.setReadOnly(true);
            PreparedStatement statement = connection.prepareStatement(sql.toString());
            statement.setQueryTimeout(5);
            for (int indice = 0; indice < parametros.size(); indice++) {
                statement.setObject(indice + 1, parametros.get(indice));
            }
            return statement;
        }, resultado -> {
            List<Map<String, Object>> registros = new ArrayList<>();
            int quantidadeColunas = resultado.getMetaData().getColumnCount();
            while (resultado.next()) {
                Map<String, Object> registro = new LinkedHashMap<>();
                for (int coluna = 1; coluna <= quantidadeColunas; coluna++) {
                    registro.put(
                            resultado.getMetaData().getColumnLabel(coluna).toLowerCase(Locale.ROOT),
                            resultado.getObject(coluna));
                }
                registros.add(registro);
            }
            return registros;
        });

    }

    private String normalizarTabela(String tabelaSolicitada) {
        return tabelaSolicitada == null ? "" : tabelaSolicitada.toLowerCase(Locale.ROOT);
    }

    private record TabelaConsulta(
            List<String> colunas,
            List<String> colunasBusca,
            String colunaOrdenacao,
            String colunaData,
            List<String> colunasDesempate) {}
}
