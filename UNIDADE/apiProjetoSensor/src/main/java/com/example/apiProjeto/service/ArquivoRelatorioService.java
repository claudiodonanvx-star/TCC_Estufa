package com.example.apiProjeto.service;

import java.awt.BasicStroke;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtils;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.plot.PiePlot;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.renderer.category.LineAndShapeRenderer;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.general.DefaultPieDataset;
import org.springframework.stereotype.Service;

@Service
public class ArquivoRelatorioService {

    private static final Locale LOCALE_CSV = Locale.forLanguageTag("pt-BR");
    private static final Set<String> SECOES_VALIDAS = Set.of(
            "resumo", "graficos", "temperatura", "umidade", "solo",
            "saude", "alertas", "tendencias", "recomendacoes", "dados");
    private static final Color VERDE = new Color(14, 125, 99);
    private static final Color AZUL = new Color(41, 182, 246);
    private static final Color LARANJA = new Color(255, 112, 67);
    private static final Color FUNDO = new Color(244, 248, 245);
    private static final Color TEXTO = new Color(17, 49, 40);

    private final ConsultaBancoLeituraService consultaBancoLeituraService;

    public ArquivoRelatorioService(ConsultaBancoLeituraService consultaBancoLeituraService) {
        this.consultaBancoLeituraService = consultaBancoLeituraService;
    }

    public ArquivoGerado gerar(String tabela, LocalDate inicio, LocalDate fim, String formato) {
        return gerar(tabela, inicio, fim, formato, "executivo",
                "resumo,graficos,saude,alertas,recomendacoes,dados");
    }

    public ArquivoGerado gerar(String tabela, LocalDate inicio, LocalDate fim, String formato,
                               String template, String secoesTexto) {
        String formatoNormalizado = normalizar(formato);
        if (!Set.of("csv", "pdf").contains(formatoNormalizado)) {
            throw new IllegalArgumentException("O formato deve ser CSV ou PDF.");
        }
        Set<String> secoes = normalizarSecoes(secoesTexto);
        List<Map<String, Object>> registros =
                consultaBancoLeituraService.consultarParaExportacao(tabela, inicio, fim);
        List<Map<String, Object>> diarios = consolidarPorDia(registros, tabela);
        Resumo resumo = calcularResumo(diarios, registros, tabela);
        Indicadores indicadores = calcularIndicadores(registros, tabela);

        String nome = "estufa_" + tabela + "_" + normalizar(template)
                + "_" + inicio + "_a_" + fim + "." + formatoNormalizado;
        byte[] conteudo = "csv".equals(formatoNormalizado)
                ? gerarCsv(tabela, inicio, fim, registros, diarios, resumo, secoes)
                : gerarPdf(tabela, inicio, fim, registros, diarios, resumo, indicadores, secoes);
        String mime = "csv".equals(formatoNormalizado)
                ? "text/csv;charset=UTF-8" : "application/pdf";
        return new ArquivoGerado(nome, mime, conteudo);
    }

    private Set<String> normalizarSecoes(String texto) {
        Set<String> secoes = Arrays.stream(
                        (texto == null ? "" : texto.toLowerCase(Locale.ROOT)).split(","))
                .map(String::trim)
                .filter(SECOES_VALIDAS::contains)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (secoes.isEmpty()) {
            secoes.addAll(Set.of("resumo", "graficos", "saude", "alertas", "recomendacoes", "dados"));
        }
        return secoes;
    }

    private String normalizar(String valor) {
        return valor == null ? "" : valor.trim().toLowerCase(Locale.ROOT);
    }

    private List<Map<String, Object>> consolidarPorDia(List<Map<String, Object>> registros, String tabela) {
        if ("relatorio_diario".equals(tabela)) {
            return registros.stream().map(registro -> {
                Map<String, Object> linha = new LinkedHashMap<>(registro);
                linha.put("data", valor(registro, "data_ref"));
                linha.put("alertas", dentroDaFaixa(registro)
                        ? 0 : inteiro(registro, "total_leituras"));
                return linha;
            }).toList();
        }
        if (!"sensor_data".equals(tabela)) return registros;

        Map<String, List<Map<String, Object>>> dias = new LinkedHashMap<>();
        for (Map<String, Object> registro : registros) {
            String data = extrairData(registro.get("coletado_em"));
            if (!data.isBlank()) {
                dias.computeIfAbsent(data, chave -> new ArrayList<>()).add(registro);
            }
        }
        List<Map<String, Object>> resultado = new ArrayList<>();
        dias.forEach((data, itens) -> {
            Map<String, Object> linha = new LinkedHashMap<>();
            linha.put("data", data);
            linha.put("temp_media", media(itens, "temperatura"));
            linha.put("temp_minima", minimo(itens, "temperatura"));
            linha.put("temp_maxima", maximo(itens, "temperatura"));
            linha.put("umidade_media", media(itens, "umidade"));
            linha.put("umidade_minima", minimo(itens, "umidade"));
            linha.put("umidade_maxima", maximo(itens, "umidade"));
            linha.put("solo_media", media(itens, "umidade_solo"));
            linha.put("solo_minima", minimo(itens, "umidade_solo"));
            linha.put("solo_maxima", maximo(itens, "umidade_solo"));
            linha.put("total_leituras", itens.size());
            linha.put("alertas", contarAlertas(itens));
            resultado.add(linha);
        });
        return resultado;
    }

    private String extrairData(Object valor) {
        if (valor == null) return "";
        String texto = valor.toString();
        int posicao = texto.indexOf('T');
        if (posicao > 0) return texto.substring(0, posicao);
        return texto.length() >= 10 ? texto.substring(0, 10) : "";
    }

    private Double numero(Object valor) {
        if (valor instanceof Number numero) return numero.doubleValue();
        if (valor == null) return null;
        try {
            return Double.parseDouble(valor.toString().replace(",", "."));
        } catch (NumberFormatException erro) {
            return null;
        }
    }

    private double media(List<Map<String, Object>> itens, String chave) {
        return itens.stream().map(item -> numero(item.get(chave))).filter(valor -> valor != null)
                .mapToDouble(Double::doubleValue).average().orElse(0);
    }

    private double minimo(List<Map<String, Object>> itens, String chave) {
        return itens.stream().map(item -> numero(item.get(chave))).filter(valor -> valor != null)
                .mapToDouble(Double::doubleValue).min().orElse(0);
    }

    private double maximo(List<Map<String, Object>> itens, String chave) {
        return itens.stream().map(item -> numero(item.get(chave))).filter(valor -> valor != null)
                .mapToDouble(Double::doubleValue).max().orElse(0);
    }

    private Resumo calcularResumo(List<Map<String, Object>> linhas,
                                  List<Map<String, Object>> registros, String tabela) {
        if ("sensor_data".equals(tabela)) {
            return new Resumo(registros.size(),
                    media(registros, "temperatura"),
                    minimo(registros, "temperatura"),
                    maximo(registros, "temperatura"),
                    media(registros, "umidade"),
                    minimo(registros, "umidade"),
                    maximo(registros, "umidade"),
                    media(registros, "umidade_solo"));
        }
        if ("relatorio_diario".equals(tabela)) {
            double temperatura = 0;
            double umidade = 0;
            double solo = 0;
            int leituras = 0;
            double tempMin = Double.POSITIVE_INFINITY;
            double tempMax = Double.NEGATIVE_INFINITY;
            double umidadeMin = Double.POSITIVE_INFINITY;
            double umidadeMax = Double.NEGATIVE_INFINITY;
            for (Map<String, Object> registro : registros) {
                int peso = inteiro(registro, "total_leituras");
                if (peso <= 0) continue;
                leituras += peso;
                temperatura += coluna(registro, "temp_media", "temperatura") * peso;
                umidade += coluna(registro, "umidade_media", "umidade") * peso;
                solo += coluna(registro, "solo_media", "umidade_solo") * peso;
                tempMin = Math.min(tempMin, coluna(registro, "temp_minima", "temperatura"));
                tempMax = Math.max(tempMax, coluna(registro, "temp_maxima", "temperatura"));
                umidadeMin = Math.min(umidadeMin, coluna(registro, "umidade_minima", "umidade"));
                umidadeMax = Math.max(umidadeMax, coluna(registro, "umidade_maxima", "umidade"));
            }
            if (leituras > 0) {
                return new Resumo(leituras, temperatura / leituras,
                        tempMin, tempMax, umidade / leituras,
                        umidadeMin, umidadeMax, solo / leituras);
            }
        }
        if (linhas.isEmpty()) return new Resumo(0, 0, 0, 0, 0, 0, 0, 0);
        double temp = 0, umidade = 0, solo = 0;
        double tempMin = Double.POSITIVE_INFINITY, tempMax = Double.NEGATIVE_INFINITY;
        double umidadeMin = Double.POSITIVE_INFINITY, umidadeMax = Double.NEGATIVE_INFINITY;
        double soloMin = Double.POSITIVE_INFINITY;
        int leituras = 0;
        for (Map<String, Object> linha : linhas) {
            double tempValor = coluna(linha, "temp_media", "temperatura");
            double umidValor = coluna(linha, "umidade_media", "umidade");
            double soloValor = coluna(linha, "solo_media", "umidade_solo");
            temp += tempValor;
            umidade += umidValor;
            solo += soloValor;
            tempMin = Math.min(tempMin, coluna(linha, "temp_minima", "temperatura"));
            tempMax = Math.max(tempMax, coluna(linha, "temp_maxima", "temperatura"));
            umidadeMin = Math.min(umidadeMin, coluna(linha, "umidade_minima", "umidade"));
            umidadeMax = Math.max(umidadeMax, coluna(linha, "umidade_maxima", "umidade"));
            soloMin = Math.min(soloMin, coluna(linha, "solo_minima", "umidade_solo"));
            Object total = linha.get("total_leituras");
            leituras += total instanceof Number numero ? numero.intValue() : 1;
        }
        int quantidade = linhas.size();
        return new Resumo(leituras, temp / quantidade,
                tempMin == Double.POSITIVE_INFINITY ? 0 : tempMin,
                tempMax == Double.NEGATIVE_INFINITY ? 0 : tempMax,
                umidade / quantidade,
                umidadeMin == Double.POSITIVE_INFINITY ? 0 : umidadeMin,
                umidadeMax == Double.NEGATIVE_INFINITY ? 0 : umidadeMax,
                solo / quantidade);
    }

    private Indicadores calcularIndicadores(List<Map<String, Object>> registros, String tabela) {
        int leituras = 0;
        int dentroDaFaixa = 0;
        int alertas = 0;
        if ("sensor_data".equals(tabela)) {
            for (Map<String, Object> registro : registros) {
                leituras++;
                if (dentroDaFaixa(registro)) {
                    dentroDaFaixa++;
                } else {
                    alertas++;
                }
            }
        } else if ("relatorio_diario".equals(tabela)) {
            for (Map<String, Object> registro : registros) {
                int peso = Math.max(0, inteiro(registro, "total_leituras"));
                if (peso == 0) continue;
                leituras += peso;
                if (dentroDaFaixa(registro)) {
                    dentroDaFaixa += peso;
                } else {
                    alertas += peso;
                }
            }
        }

        double tempoIdeal = leituras == 0 ? 0 : dentroDaFaixa * 100.0 / leituras;
        double saude = Math.max(0, Math.min(100, tempoIdeal - alertas * 0.05));
        return new Indicadores(tempoIdeal, alertas, saude);
    }

    private int contarAlertas(List<Map<String, Object>> registros) {
        return (int) registros.stream().filter(registro -> !dentroDaFaixa(registro)).count();
    }

    private boolean dentroDaFaixa(Map<String, Object> registro) {
        double temperatura = coluna(registro, "temp_media", "temperatura");
        double umidade = coluna(registro, "umidade_media", "umidade");
        double solo = coluna(registro, "solo_media", "umidade_solo");
        return temperatura >= 18 && temperatura <= 30
                && umidade >= 40 && umidade <= 80
                && solo >= 35 && solo <= 70;
    }

    private double coluna(Map<String, Object> linha, String consolidada, String bruta) {
        Double valor = numero(linha.containsKey(consolidada) ? linha.get(consolidada) : linha.get(bruta));
        return valor == null ? 0 : valor;
    }

    private String periodoRelatorio(LocalDate inicio, LocalDate fim) {
        long dias = ChronoUnit.DAYS.between(inicio, fim) + 1;
        if (dias <= 1) return "Diario";
        if (dias <= 7) return "Semanal";
        if (dias <= 31) return "Mensal";
        return "Personalizado";
    }

    private String diagnostico(String periodo, Indicadores indicadores,
                               List<Map<String, Object>> registros) {
        String risco = registros.stream()
                .map(registro -> registro.getOrDefault("significado", registro.get("mensagem")))
                .filter(valor -> valor != null && !valor.toString().isBlank())
                .map(Object::toString)
                .collect(Collectors.groupingBy(valor -> valor, LinkedHashMap::new, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse(indicadores.alertasCriticos > 0
                        ? "Desvios nos indicadores ambientais" : "Nenhum risco relevante");
        return String.format(Locale.US,
                "No periodo %s, a estufa ficou %.1f%% do tempo em faixa ideal. "
                        + "Foram detectados %d alertas criticos. Risco mais recorrente: %s.",
                periodo.toLowerCase(Locale.ROOT),
                indicadores.tempoFaixaIdealPct,
                indicadores.alertasCriticos,
                risco);
    }

    private byte[] gerarCsv(String tabela, LocalDate inicio, LocalDate fim,
                            List<Map<String, Object>> registros,
                            List<Map<String, Object>> diarios, Resumo resumo,
                            Set<String> secoes) {
        StringBuilder csv = new StringBuilder("\uFEFF");
        csv.append("ESTUFA SMART - RELATORIO PERSONALIZADO\r\n");
        csv.append("Periodo;").append(inicio).append(" a ").append(fim).append("\r\n");
        csv.append("Fonte;").append(tabela).append("\r\n");
        csv.append("Gerado em;").append(LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))).append("\r\n");

        if (secoes.contains("resumo")) {
            csv.append("\r\nRESUMO EXECUTIVO\r\n");
            csv.append("Indicador;Media;Minimo;Maximo\r\n");
            csv.append(String.format(LOCALE_CSV, "Temperatura;%.2f C;%.2f C;%.2f C\r\n",
                    resumo.tempMedia, resumo.tempMin, resumo.tempMax));
            csv.append(String.format(LOCALE_CSV, "Umidade do ar;%.2f %%;;\r\n",
                    resumo.umidadeMedia));
            csv.append(String.format(LOCALE_CSV, "Umidade do solo;%.2f %%;;\r\n",
                    resumo.soloMedia));
            csv.append("Leituras;").append(resumo.leituras).append(";;\r\n");
        }

        if (secoes.contains("recomendacoes") || secoes.contains("saude") || secoes.contains("alertas")) {
            csv.append("\r\nRECOMENDACOES\r\n");
            csv.append("Prioridade;Recomendacao\r\n");
            for (String recomendacao : gerarRecomendacoes(resumo)) {
                int separador = recomendacao.indexOf(" | ");
                csv.append(separador < 0 ? "INFO" : recomendacao.substring(0, separador)).append(";");
                csv.append(escapar(separador < 0 ? recomendacao : recomendacao.substring(separador + 3))).append("\r\n");
            }
        }

        if (secoes.contains("graficos") || secoes.contains("tendencias")
                || secoes.contains("temperatura") || secoes.contains("umidade")
                || secoes.contains("solo")) {
            csv.append("\r\nSERIE CONSOLIDADA PARA GRAFICOS\r\n");
            csv.append("Data;Temperatura media;Temperatura minima;Temperatura maxima;");
            csv.append("Umidade ar media;Umidade ar minima;Umidade ar maxima;");
            csv.append("Solo medio;Solo minimo;Solo maximo;Leituras\r\n");
            for (Map<String, Object> linha : diarios) {
                csv.append(String.format(LOCALE_CSV,
                        "%s;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%d\r\n",
                        valor(linha, "data"),
                        coluna(linha, "temp_media", "temperatura"),
                        coluna(linha, "temp_minima", "temperatura"),
                        coluna(linha, "temp_maxima", "temperatura"),
                        coluna(linha, "umidade_media", "umidade"),
                        coluna(linha, "umidade_minima", "umidade"),
                        coluna(linha, "umidade_maxima", "umidade"),
                        coluna(linha, "solo_media", "umidade_solo"),
                        coluna(linha, "solo_minima", "umidade_solo"),
                        coluna(linha, "solo_maxima", "umidade_solo"),
                        inteiro(linha, "total_leituras")));
            }
        }

        if (secoes.contains("dados")) {
            csv.append("\r\nDADOS DETALHADOS\r\n");
            if (!registros.isEmpty()) {
                List<String> colunas = new ArrayList<>(registros.get(0).keySet());
                csv.append(colunas.stream().map(this::rotuloColunaCsv)
                        .collect(Collectors.joining(";"))).append("\r\n");
                for (Map<String, Object> registro : registros) {
                    csv.append(colunas.stream()
                            .map(coluna -> formatarCampoCsv(registro.get(coluna)))
                            .collect(Collectors.joining(";"))).append("\r\n");
                }
            } else {
                csv.append("Sem dados disponiveis\r\n");
            }
        }
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    private String formatarCampoCsv(Object valor) {
        if (valor instanceof Number numero) {
            return numero.toString().replace('.', ',');
        }
        return escapar(valor);
    }

    private String rotuloColunaCsv(String coluna) {
        return Arrays.stream(coluna.split("_"))
                .map(palavra -> palavra.isEmpty()
                        ? palavra
                        : palavra.substring(0, 1).toUpperCase(LOCALE_CSV)
                                + palavra.substring(1))
                .collect(Collectors.joining(" "));
    }

    private String escapar(Object valor) {
        String texto = valor == null ? "" : valor.toString();
        return "\"" + texto.replace("\"", "\"\"") + "\"";
    }

    private byte[] gerarPdf(String tabela, LocalDate inicio, LocalDate fim,
                            List<Map<String, Object>> registros,
                            List<Map<String, Object>> diarios, Resumo resumo, Indicadores indicadores,
                            Set<String> secoes) {
        try (PDDocument document = new PDDocument()) {
            int paginaAtual = 1;
            PDRectangle landscape = new PDRectangle(PDRectangle.A4.getHeight(), PDRectangle.A4.getWidth());
            String periodo = periodoRelatorio(inicio, fim);
            boolean mostrarGraficos = !diarios.isEmpty()
                    && (secoes.contains("graficos") || secoes.contains("tendencias")
                            || secoes.contains("temperatura") || secoes.contains("umidade")
                            || secoes.contains("solo"));

            PDPage capa = new PDPage(PDRectangle.A4);
            document.addPage(capa);
            try (PDPageContentStream stream = new PDPageContentStream(document, capa)) {
                cabecalho(stream, capa, "ESTUFA SMART", "RELATORIO INTELIGENTE", periodo);
                float y = 690;
                y = titulo(stream, y, "Resumo executivo");
                y = metadata(stream, y, "Periodo", inicio + " a " + fim);
                y = metadata(stream, y, "Leituras analisadas",
                        String.valueOf(resumo.leituras));
                y -= 20;

                cartao(stream, 50, y - 75, 155, 75, "TEMPERATURA",
                        String.format(Locale.US, "%.2f C", resumo.tempMedia));
                cartao(stream, 228, y - 75, 155, 75, "UMIDADE DO AR",
                        String.format(Locale.US, "%.2f%%", resumo.umidadeMedia));
                cartao(stream, 406, y - 75, 155, 75, "UMIDADE DO SOLO",
                        String.format(Locale.US, "%.2f%%", resumo.soloMedia));

                y -= 110;
                y = titulo(stream, y, "Recomendacoes");
                if (secoes.contains("recomendacoes") || secoes.contains("saude") || secoes.contains("alertas")) {
                    for (String recomendacao : gerarRecomendacoes(resumo)) {
                        int separador = recomendacao.indexOf(" | ");
                        String texto = separador < 0
                                ? recomendacao : recomendacao.substring(separador + 3);
                        y = textoBullet(stream, capa, y, texto);
                    }
                }
                y -= 8;
                y = titulo(stream, y, "Diagnostico");
                texto(stream, capa, y, 50, diagnostico(periodo, indicadores, registros));
                rodape(stream, capa, paginaAtual++);
            }

            if (mostrarGraficos) {
                PDPage chartPage = new PDPage(landscape);
                document.addPage(chartPage);
                try (PDPageContentStream stream = new PDPageContentStream(document, chartPage)) {
                    cabecalho(stream, chartPage, "ESTUFA SMART",
                            "EVOLUCAO DOS INDICADORES", periodo);
                    byte[] lineChart = criarGraficoLinha(diarios);
                    PDImageXObject imagem = PDImageXObject.createFromByteArray(document, lineChart, "grafico");
                    stream.drawImage(imagem, 45, 155, 752, 326);
                    legenda(stream, 45, 130);
                    rodape(stream, chartPage, paginaAtual++);
                }

                PDPage comparisonPage = new PDPage(PDRectangle.A4);
                document.addPage(comparisonPage);
                try (PDPageContentStream stream = new PDPageContentStream(document, comparisonPage)) {
                    cabecalho(stream, comparisonPage, "ESTUFA SMART",
                            "ANALISE DE ALERTAS E SAUDE", periodo);
                    byte[] barChart = criarGraficoAlertas(diarios);
                    PDImageXObject imagemBarra = PDImageXObject.createFromByteArray(document, barChart, "barras");
                    stream.drawImage(imagemBarra, 45, 470, 505, 260);
                    byte[] pieChart = criarGraficoSaude(indicadores.tempoFaixaIdealPct);
                    PDImageXObject imagemPizza = PDImageXObject.createFromByteArray(document, pieChart, "saude");
                    stream.drawImage(imagemPizza, 70, 160, 280, 220);
                    titulo(stream, 350, 350, "Indicadores");
                    texto(stream, comparisonPage, 320, 350,
                            String.format(Locale.US, "Tempo em faixa ideal: %.1f%%",
                                    indicadores.tempoFaixaIdealPct));
                    texto(stream, comparisonPage, 290, 350,
                            String.format(Locale.US, "Indice de saude: %.1f",
                                    indicadores.indiceSaude));
                    rodape(stream, comparisonPage, paginaAtual++);
                }
            }

            if (secoes.contains("dados")) {
                PDPage detailPage = new PDPage(PDRectangle.A4);
                document.addPage(detailPage);
                try (PDPageContentStream stream = new PDPageContentStream(document, detailPage)) {
                    cabecalho(stream, detailPage, "ESTUFA SMART",
                            "DETALHAMENTO CONSOLIDADO", periodo);
                    float y = 690;
                    y = titulo(stream, y, "Serie diaria");
                    for (Map<String, Object> linha : diarios) {
                        if (y < 70) break;
                        String texto = String.format(Locale.ROOT,
                                "%s  |  T %.1f C  |  Ar %.1f%%  |  Solo %.1f%%  |  %d leituras",
                                valor(linha, "data"),
                                coluna(linha, "temp_media", "temperatura"),
                                coluna(linha, "umidade_media", "umidade"),
                                coluna(linha, "solo_media", "umidade_solo"),
                                inteiro(linha, "total_leituras"));
                        y = escreverTexto(stream, detailPage, y, 50, 9, TEXTO, texto);
                        y -= 4;
                    }
                    rodape(stream, detailPage, paginaAtual++);
                }
            }

            ByteArrayOutputStream saida = new ByteArrayOutputStream();
            document.save(saida);
            return saida.toByteArray();
        } catch (IOException erro) {
            throw new IllegalStateException("Nao foi possivel gerar o PDF profissional.", erro);
        }
    }

    private byte[] criarGraficoLinha(List<Map<String, Object>> diarios) throws IOException {
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        int bloco = 1;
        for (Map<String, Object> linha : diarios) {
            String label = "B" + bloco++;
            dataset.addValue(coluna(linha, "temp_media", "temperatura"), "Temperatura C", label);
            dataset.addValue(coluna(linha, "umidade_media", "umidade"), "Umidade do ar %", label);
            dataset.addValue(coluna(linha, "solo_media", "umidade_solo"), "Umidade do solo %", label);
        }
        JFreeChart chart = ChartFactory.createLineChart(
                "Evolucao consolidada", "Blocos", "Valor",
                dataset, PlotOrientation.VERTICAL, true, true, false);
        chart.setBackgroundPaint(Color.WHITE);
        CategoryPlot plot = chart.getCategoryPlot();
        plot.setBackgroundPaint(Color.WHITE);
        plot.setRangeGridlinePaint(new Color(210, 225, 216));
        LineAndShapeRenderer renderer = (LineAndShapeRenderer) plot.getRenderer();
        renderer.setSeriesPaint(0, LARANJA);
        renderer.setSeriesPaint(1, AZUL);
        renderer.setSeriesPaint(2, VERDE);
        renderer.setSeriesStroke(0, new BasicStroke(2.5f));
        renderer.setSeriesStroke(1, new BasicStroke(2.5f));
        renderer.setSeriesStroke(2, new BasicStroke(2.5f));
        boolean pontoUnico = diarios.size() == 1;
        renderer.setSeriesShapesVisible(0, pontoUnico);
        renderer.setSeriesShapesVisible(1, pontoUnico);
        renderer.setSeriesShapesVisible(2, pontoUnico);
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        ChartUtils.writeChartAsPNG(saida, chart, 1500, 650);
        return saida.toByteArray();
    }

    private byte[] criarGraficoAlertas(List<Map<String, Object>> diarios) throws IOException {
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        int bloco = 1;
        for (Map<String, Object> linha : diarios) {
            dataset.addValue(inteiro(linha, "alertas"), "Alertas", "B" + bloco++);
        }
        JFreeChart chart = ChartFactory.createBarChart(
                "Alertas por bloco", "Bloco", "Quantidade",
                dataset, PlotOrientation.VERTICAL, false, true, false);
        chart.setBackgroundPaint(Color.WHITE);
        chart.getCategoryPlot().getRenderer().setSeriesPaint(0, LARANJA);
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        ChartUtils.writeChartAsPNG(saida, chart, 1000, 500);
        return saida.toByteArray();
    }

    private byte[] criarGraficoSaude(double ideal) throws IOException {
        DefaultPieDataset<String> dataset = new DefaultPieDataset<>();
        dataset.setValue("Faixa ideal", ideal);
        dataset.setValue("Fora da faixa", Math.max(0, 100 - ideal));
        JFreeChart chart = ChartFactory.createPieChart(
                "Faixa ideal x fora da faixa", dataset, true, true, false);
        chart.setBackgroundPaint(Color.WHITE);
        PiePlot<?> plot = (PiePlot<?>) chart.getPlot();
        plot.setSectionPaint("Faixa ideal", VERDE);
        plot.setSectionPaint("Fora da faixa", LARANJA);
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        ChartUtils.writeChartAsPNG(saida, chart, 700, 500);
        return saida.toByteArray();
    }

    private void cabecalho(PDPageContentStream stream, PDPage page,
                           String marca, String titulo, String periodo) throws IOException {
        stream.setNonStrokingColor(VERDE);
        stream.addRect(0, page.getMediaBox().getHeight() - 78, page.getMediaBox().getWidth(), 78);
        stream.fill();
        stream.beginText();
        stream.setNonStrokingColor(Color.WHITE);
        stream.setFont(PDType1Font.HELVETICA_BOLD, 18);
        stream.newLineAtOffset(40, page.getMediaBox().getHeight() - 38);
        stream.showText(marca);
        stream.setFont(PDType1Font.HELVETICA, 10);
        stream.newLineAtOffset(0, -18);
        stream.showText(titulo + "  |  " + periodo);
        stream.endText();
    }

    private float titulo(PDPageContentStream stream, float y, String texto) throws IOException {
        return titulo(stream, y, 50, texto);
    }

    private float titulo(PDPageContentStream stream, float y, float x,
                         String texto) throws IOException {
        stream.setNonStrokingColor(VERDE);
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 16);
        stream.newLineAtOffset(x, y);
        stream.showText(texto);
        stream.endText();
        return y - 28;
    }

    private float metadata(PDPageContentStream stream, float y,
                           String label, String valor) throws IOException {
        stream.setFont(PDType1Font.HELVETICA_BOLD, 9);
        stream.setNonStrokingColor(new Color(80, 100, 92));
        stream.beginText();
        stream.newLineAtOffset(50, y);
        stream.showText(label.toUpperCase(Locale.ROOT));
        stream.endText();
        stream.setFont(PDType1Font.HELVETICA, 11);
        stream.setNonStrokingColor(TEXTO);
        stream.beginText();
        stream.newLineAtOffset(170, y);
        stream.showText(valor);
        stream.endText();
        return y - 22;
    }

    private void cartao(PDPageContentStream stream, float x, float y,
                        float largura, float altura, String titulo, String valor) throws IOException {
        stream.setNonStrokingColor(Color.WHITE);
        stream.addRect(x, y, largura, altura);
        stream.fill();
        stream.setStrokingColor(new Color(210, 226, 216));
        stream.addRect(x, y, largura, altura);
        stream.stroke();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 8);
        stream.setNonStrokingColor(new Color(90, 110, 101));
        stream.beginText();
        stream.newLineAtOffset(x + 12, y + 52);
        stream.showText(titulo);
        stream.endText();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 18);
        stream.setNonStrokingColor(VERDE);
        stream.beginText();
        stream.newLineAtOffset(x + 12, y + 24);
        stream.showText(valor);
        stream.endText();
    }

    private float textoBullet(PDPageContentStream stream, PDPage page,
                              float y, String texto) throws IOException {
        stream.setNonStrokingColor(VERDE);
        stream.addRect(50, y - 3, 5, 5);
        stream.fill();
        return this.texto(stream, page, y - 3, 64, texto);
    }

    private float texto(PDPageContentStream stream, PDPage page,
                        float y, float x, String texto) throws IOException {
        float tamanho = 10;
        float maxWidth = (page == null ? PDRectangle.A4.getWidth() : page.getMediaBox().getWidth())
                - x - 40;
        List<String> linhas = new ArrayList<>();
        StringBuilder linha = new StringBuilder();
        for (String palavra : texto.trim().split("\\s+")) {
            String candidata = linha.isEmpty() ? palavra : linha + " " + palavra;
            if (!linha.isEmpty()
                    && PDType1Font.HELVETICA.getStringWidth(candidata) / 1000 * tamanho > maxWidth) {
                linhas.add(linha.toString());
                linha.setLength(0);
                linha.append(palavra);
            } else {
                if (!linha.isEmpty()) linha.append(' ');
                linha.append(palavra);
            }
        }
        if (!linha.isEmpty()) linhas.add(linha.toString());

        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA, tamanho);
        stream.setNonStrokingColor(TEXTO);
        stream.newLineAtOffset(x, y);
        for (int i = 0; i < linhas.size(); i++) {
            if (i > 0) stream.newLineAtOffset(0, -12);
            stream.showText(linhas.get(i));
        }
        stream.endText();
        return y - linhas.size() * 14 - 4;
    }

    private float escreverTexto(PDPageContentStream stream, PDPage page, float y,
                                float x, float tamanho, Color cor, String texto) throws IOException {
        float maxWidth = page.getMediaBox().getWidth() - x - 40;
        List<String> linhas = quebrarLinhas(texto, tamanho, maxWidth);
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA, tamanho);
        stream.setNonStrokingColor(cor);
        stream.newLineAtOffset(x, y);
        for (int i = 0; i < linhas.size(); i++) {
            if (i > 0) stream.newLineAtOffset(0, -12);
            stream.showText(linhas.get(i));
        }
        stream.endText();
        return y - linhas.size() * 12 - 4;
    }

    private List<String> quebrarLinhas(String texto, float tamanho, float maxWidth) throws IOException {
        List<String> linhas = new ArrayList<>();
        StringBuilder linha = new StringBuilder();
        for (String palavra : texto.trim().split("\\s+")) {
            String candidata = linha.isEmpty() ? palavra : linha + " " + palavra;
            if (!linha.isEmpty()
                    && PDType1Font.HELVETICA.getStringWidth(candidata) / 1000 * tamanho > maxWidth) {
                linhas.add(linha.toString());
                linha.setLength(0);
                linha.append(palavra);
            } else {
                if (!linha.isEmpty()) linha.append(' ');
                linha.append(palavra);
            }
        }
        if (!linha.isEmpty()) linhas.add(linha.toString());
        return linhas;
    }

    private void legenda(PDPageContentStream stream, float x, float y) throws IOException {
        stream.setFont(PDType1Font.HELVETICA, 9);
        stream.setNonStrokingColor(TEXTO);
        stream.beginText();
        stream.newLineAtOffset(x, y);
        stream.showText("Laranja: temperatura  |  Azul: umidade do ar  |  Verde: umidade do solo");
        stream.endText();
    }

    private void rodape(PDPageContentStream stream, PDPage page, int pagina) throws IOException {
        stream.setStrokingColor(new Color(210, 226, 216));
        stream.moveTo(40, 35);
        stream.lineTo(page.getMediaBox().getWidth() - 40, 35);
        stream.stroke();
        stream.setFont(PDType1Font.HELVETICA, 8);
        stream.setNonStrokingColor(new Color(100, 115, 108));
        stream.beginText();
        stream.newLineAtOffset(40, 20);
        stream.showText("Estufa Smart  |  Gerado em "
                + LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))
                + "  |  Pagina " + pagina);
        stream.endText();
    }

    private List<String> gerarRecomendacoes(Resumo resumo) {
        List<String> resultado = new ArrayList<>();
        if (resumo.tempMedia > 30) resultado.add("ALTA | Temperatura elevada: revisar ventilacao e sombreamento.");
        else if (resumo.tempMedia < 18) resultado.add("MEDIA | Temperatura baixa: avaliar aquecimento ou protecao.");
        else resultado.add("OK | Temperatura media dentro da faixa operacional.");
        if (resumo.umidadeMedia > 80) resultado.add("ALTA | Umidade elevada: aumentar circulacao e prevenir fungos.");
        else if (resumo.umidadeMedia < 40) resultado.add("MEDIA | Umidade baixa: avaliar nebulizacao.");
        else resultado.add("OK | Umidade do ar dentro da faixa operacional.");
        if (resumo.soloMedia < 35) resultado.add("ALTA | Solo seco: revisar irrigacao e atuadores.");
        else if (resumo.soloMedia > 70) resultado.add("MEDIA | Solo muito umido: revisar drenagem.");
        else resultado.add("OK | Umidade do solo dentro da faixa operacional.");
        if (resumo.leituras == 0) resultado.add("ATENCAO | Sem leituras no periodo.");
        return resultado;
    }

    private String formato(double valor) {
        return String.format(Locale.ROOT, "%.2f", valor);
    }

    private String valor(Map<String, Object> linha, String chave) {
        Object valor = linha.get(chave);
        if (valor == null) valor = linha.get("data_ref");
        return valor == null ? "" : valor.toString();
    }

    private int inteiro(Map<String, Object> linha, String chave) {
        Object valor = linha.get(chave);
        return valor instanceof Number numero ? numero.intValue() : 0;
    }

    private record Indicadores(double tempoFaixaIdealPct, int alertasCriticos, double indiceSaude) {}

    private record Resumo(int leituras, double tempMedia, double tempMin, double tempMax,
                          double umidadeMedia, double umidadeMin, double umidadeMax,
                          double soloMedia) {}

    public record ArquivoGerado(String nome, String tipoMime, byte[] conteudo) {}
}
