package com.example.apiProjeto.service;

import java.sql.PreparedStatement;
import java.time.LocalDate;
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
    private static final int TAMANHO_MAXIMO_TERMO = 100;

    private static final Map<String, TabelaConsulta> TABELAS = Map.of(
            "sensor_data", new TabelaConsulta(
                    List.of("id", "coletado_em", "temperatura", "umidade", "umidade_solo", "significado"),
                    List.of("significado"),
                    "coletado_em",
                    List.of("id")),
            "cultivos", new TabelaConsulta(
                    List.of("id", "nome", "tipo", "temperatura_minima", "temperatura_maxima",
                            "umidade_minima", "umidade_maxima", "umidade_solo_minima",
                            "umidade_solo_maxima", "habilitada"),
                    List.of("nome", "tipo"),
                    "id",
                    List.of()),
            "alertas", new TabelaConsulta(
                    List.of("id", "tipo", "severidade", "valor", "limite_min", "limite_max",
                            "mensagem", "gerado_em"),
                    List.of("tipo", "severidade", "mensagem"),
                    "gerado_em",
                    List.of("id")),
            "relatorio_diario", new TabelaConsulta(
                    List.of("id", "data_ref", "temp_media", "temp_minima", "temp_maxima",
                            "umidade_media", "umidade_minima", "umidade_maxima", "solo_media",
                            "solo_minima", "solo_maxima", "total_leituras", "atualizado_em"),
                    List.of(),
                    "data_ref",
                    List.of()));

    private final JdbcTemplate jdbcTemplate;

    public ConsultaBancoLeituraService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> consultar(String tabelaSolicitada, String termo, int quantidade, String ordem) {
        String tabela = tabelaSolicitada == null ? "" : tabelaSolicitada.toLowerCase(Locale.ROOT);
        TabelaConsulta definicao = TABELAS.get(tabela);
        if (definicao == null) {
            throw new IllegalArgumentException("Tabela não permitida para consulta do agente.");
        }

        String busca = termo == null ? "" : termo.trim();
        if (busca.length() > TAMANHO_MAXIMO_TERMO) {
            throw new IllegalArgumentException("O termo de busca excede o tamanho máximo permitido.");
        }

        int limite = Math.max(1, Math.min(LIMITE_MAXIMO, quantidade));
        String direcao = "antigos".equalsIgnoreCase(ordem) ? "ASC" : "DESC";
        StringBuilder sql = new StringBuilder("SELECT ")
                .append(String.join(", ", definicao.colunas()))
                .append(" FROM ")
                .append(tabela);
        List<Object> parametros = new ArrayList<>();

        if (!busca.isBlank()) {
            if (tabela.equals("relatorio_diario")) {
                try {
                    parametros.add(LocalDate.parse(busca));
                } catch (DateTimeParseException erro) {
                    throw new IllegalArgumentException(
                            "Para buscar relatórios, informe a data no formato AAAA-MM-DD.", erro);
                }
                sql.append(" WHERE data_ref = ?");
            } else {
                sql.append(" WHERE ")
                        .append(String.join(" OR ", definicao.colunasBusca().stream()
                                .map(coluna -> coluna + " LIKE ?")
                                .toList()));
                String padrao = "%" + busca + "%";
                definicao.colunasBusca().forEach(coluna -> parametros.add(padrao));
            }
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

        List<Map<String, Object>> linhas = jdbcTemplate.query(connection -> {
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

        return Map.of(
                "tabela", tabela,
                "quantidadeRetornada", linhas.size(),
                "limiteAplicado", limite,
                "registros", linhas);
    }

    private record TabelaConsulta(
            List<String> colunas,
            List<String> colunasBusca,
            String colunaOrdenacao,
            List<String> colunasDesempate) {}
}
