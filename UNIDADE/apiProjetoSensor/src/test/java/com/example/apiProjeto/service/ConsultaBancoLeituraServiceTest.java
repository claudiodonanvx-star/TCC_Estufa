package com.example.apiProjeto.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.JdbcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.jdbc.Sql;

@JdbcTest
@Import({ConsultaBancoLeituraService.class, ArquivoRelatorioService.class})
@Sql(statements = {
        "DROP TABLE IF EXISTS sensor_data",
        "DROP TABLE IF EXISTS cultivos",
        "DROP TABLE IF EXISTS alertas",
        "DROP TABLE IF EXISTS relatorio_diario",
        "CREATE TABLE sensor_data (id BIGINT PRIMARY KEY, coletado_em TIMESTAMP, temperatura REAL, "
                + "umidade REAL, umidade_solo REAL, significado VARCHAR(100))",
        "CREATE TABLE cultivos (id BIGINT PRIMARY KEY, nome VARCHAR(100), tipo VARCHAR(100), "
                + "temperatura_minima REAL, temperatura_maxima REAL, umidade_minima REAL, "
                + "umidade_maxima REAL, umidade_solo_minima REAL, umidade_solo_maxima REAL, habilitada BOOLEAN)",
        "CREATE TABLE alertas (id BIGINT PRIMARY KEY, tipo VARCHAR(20), severidade VARCHAR(10), "
                + "valor REAL, limite_min REAL, limite_max REAL, mensagem VARCHAR(200), gerado_em TIMESTAMP)",
        "CREATE TABLE relatorio_diario (id BIGINT PRIMARY KEY, data_ref DATE, temp_media DOUBLE, "
                + "temp_minima DOUBLE, temp_maxima DOUBLE, umidade_media DOUBLE, umidade_minima DOUBLE, "
                + "umidade_maxima DOUBLE, solo_media DOUBLE, solo_minima DOUBLE, solo_maxima DOUBLE, "
                + "total_leituras INTEGER, atualizado_em TIMESTAMP)",
        "INSERT INTO sensor_data (id, coletado_em, temperatura, umidade, umidade_solo, significado) "
                + "VALUES (1, TIMESTAMP '2026-10-28 10:00:00', 24.0, 60.0, 35.0, 'estufa saudável')",
        "INSERT INTO cultivos (id, nome, tipo, temperatura_minima, temperatura_maxima, umidade_minima, "
                + "umidade_maxima, umidade_solo_minima, umidade_solo_maxima, habilitada) "
                + "VALUES (1, 'Tomate', 'Fruto', 18, 30, 50, 80, 40, 70, TRUE)",
        "INSERT INTO alertas (id, tipo, severidade, valor, limite_min, limite_max, mensagem, gerado_em) "
                + "VALUES (1, 'TEMPERATURA', 'ATENCAO', 32, 18, 30, 'Temperatura alta', "
                + "TIMESTAMP '2026-10-28 10:00:00')",
        "INSERT INTO relatorio_diario (id, data_ref, temp_media, temp_minima, temp_maxima, "
                + "umidade_media, umidade_minima, umidade_maxima, solo_media, solo_minima, solo_maxima, "
                + "total_leituras, atualizado_em) VALUES (1, DATE '2026-10-28', 24, 20, 28, 60, 50, 70, "
                + "55, 45, 65, 20, TIMESTAMP '2026-10-28 23:00:00')"
})
class ConsultaBancoLeituraServiceTest {

    @Autowired
    private ConsultaBancoLeituraService service;

    @Autowired
    private ArquivoRelatorioService arquivoRelatorioService;

    @Test
    void searchesOperationalDataAndReturnsOnlyWhitelistedColumns() {
        Map<String, Object> resultado = service.consultar("sensor_data", "saudável", 10, "recentes");

        assertEquals(1, resultado.get("quantidadeRetornada"));
        @SuppressWarnings("unchecked")
        Map<String, Object> registro = ((java.util.List<Map<String, Object>>) resultado.get("registros")).get(0);
        assertEquals(1L, ((Number) registro.get("id")).longValue());
        assertFalse(registro.containsKey("email"));
        assertFalse(registro.containsKey("senha"));
    }

    @Test
    void treatsSearchTermAsAValueRatherThanSql() {
        Map<String, Object> resultado = service.consultar("sensor_data", "' OR 1=1 --", 50, "recentes");

        assertEquals(0, resultado.get("quantidadeRetornada"));
    }

    @Test
    void searchesEveryAllowedOperationalTable() {
        assertEquals(1, service.consultar("cultivos", "Tomate", 10, "recentes")
                .get("quantidadeRetornada"));
        assertEquals(1, service.consultar("alertas", "Temperatura alta", 10, "recentes")
                .get("quantidadeRetornada"));
        assertEquals(1, service.consultar("relatorio_diario", "2026-10-28", 10, "recentes")
                .get("quantidadeRetornada"));
    }

    @Test
    void filtersSensorReadingsByInclusiveDateRange() {
        Map<String, Object> resultado = service.consultar(
                "sensor_data", "", java.time.LocalDate.parse("2026-10-28"),
                java.time.LocalDate.parse("2026-10-28"), 50, "recentes");

        assertEquals(1, resultado.get("quantidadeRetornada"));
    }

    @Test
    void generatesCsvAndPdfDownloadsForRequestedPeriod() {
        ArquivoRelatorioService.ArquivoGerado csv = arquivoRelatorioService.gerar(
                "sensor_data", java.time.LocalDate.parse("2026-10-28"),
                java.time.LocalDate.parse("2026-10-28"), "csv");
        ArquivoRelatorioService.ArquivoGerado pdf = arquivoRelatorioService.gerar(
                "sensor_data", java.time.LocalDate.parse("2026-10-28"),
                java.time.LocalDate.parse("2026-10-28"), "pdf");

        assertEquals("text/csv;charset=UTF-8", csv.tipoMime());
        assertTrue(new String(csv.conteudo(), java.nio.charset.StandardCharsets.UTF_8)
                .contains("estufa saudável"));
        assertEquals("application/pdf", pdf.tipoMime());
        assertTrue(new String(pdf.conteudo(), java.nio.charset.StandardCharsets.US_ASCII)
                .startsWith("%PDF-1.4"));
    }

    @Test
    void rejectsTablesOutsideTheOperationalAllowlist() {
        assertThrows(
                IllegalArgumentException.class,
                () -> service.consultar("usuarios", "", 10, "recentes"));
    }

    @Test
    void capsRequestedRowsAndRejectsInvalidReportDates() {
        Map<String, Object> resultado = service.consultar("sensor_data", "", 500, "recentes");

        assertEquals(50, resultado.get("limiteAplicado"));
        assertThrows(
                IllegalArgumentException.class,
                () -> service.consultar("relatorio_diario", "ontem", 10, "recentes"));
    }
}
