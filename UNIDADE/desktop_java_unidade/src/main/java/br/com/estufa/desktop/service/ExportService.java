package br.com.estufa.desktop.service;

import br.com.estufa.desktop.model.PeriodData;
import br.com.estufa.desktop.model.SensorData;
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

import java.awt.BasicStroke;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class ExportService {

    private static final String SEPARADOR_CSV = ";";
    private static final String CABECALHO_CSV_CONSOLIDADO =
            "Data;Temperatura media (C);Temperatura minima (C);Temperatura maxima (C);"
                    + "Umidade do ar media (%);Umidade do ar minima (%);Umidade do ar maxima (%);"
                    + "Umidade do solo media (%);Umidade do solo minima (%);"
                    + "Umidade do solo maxima (%);Total de leituras";
    private static final Locale LOCALE_CSV = Locale.forLanguageTag("pt-BR");
    private static final Color VERDE = new Color(14, 125, 99);
    private static final Color AZUL = new Color(41, 182, 246);
    private static final Color LARANJA = new Color(255, 112, 67);

    public void exportConsolidatedCsv(Path path, String content) throws IOException {
        if (content == null || content.isBlank()) {
            throw new IOException("A API retornou um CSV vazio.");
        }

        String normalized = content.startsWith("\uFEFF") ? content.substring(1) : content;
        String[] linhas = normalized.split("\\R");
        String[] cabecalho = linhas[0].split("[;,]", -1);
        if (cabecalho.length != 11 || !cabecalho[0].equalsIgnoreCase("data")) {
            throw new IOException("O CSV retornado pela API possui um formato inesperado.");
        }

        String separadorOrigem = linhas[0].contains(";") ? ";" : ",";
        StringBuilder csv = new StringBuilder("\uFEFF").append(CABECALHO_CSV_CONSOLIDADO);
        for (int linha = 1; linha < linhas.length; linha++) {
            if (linhas[linha].isBlank()) {
                continue;
            }

            String[] campos = linhas[linha].split(separadorOrigem, -1);
            if (campos.length != 11) {
                throw new IOException("A linha " + (linha + 1)
                        + " do CSV retornado pela API possui colunas inesperadas.");
            }

            csv.append("\r\n").append(campos[0]);
            for (int coluna = 1; coluna < campos.length; coluna++) {
                csv.append(SEPARADOR_CSV);
                String valor = campos[coluna];
                if (",".equals(separadorOrigem) && coluna < 10) {
                    valor = valor.replace('.', ',');
                }
                csv.append(valor);
            }
        }

        Files.writeString(path, csv, StandardCharsets.UTF_8);
    }

    public void exportCsv(Path path, PeriodData data) throws IOException {
        List<String> linhas = new ArrayList<>();
        linhas.add("ESTUFA SMART - RELATORIO PROFISSIONAL");
        linhas.add("periodo;" + data.getPeriodType().getLabel());
        linhas.add("gerado_em;" + LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));

        linhas.add("");
        linhas.add("RESUMO EXECUTIVO");
        linhas.add("indicador;media;minimo;maximo");
        linhas.add(String.format(LOCALE_CSV, "temperatura;%.2f C;;;",
                data.getKpis().temperaturaMedia()));
        linhas.add(String.format(LOCALE_CSV, "umidade_do_ar;%.2f%%;;;",
                data.getKpis().umidadeMedia()));
        linhas.add(String.format(LOCALE_CSV, "umidade_do_solo;%.2f%%;;;",
                data.getKpis().umidadeSoloMedia()));
        linhas.add(String.format(LOCALE_CSV, "tempo_em_faixa_ideal;%.2f%%;;;",
                data.getKpis().tempoFaixaIdealPct()));
        linhas.add(String.format(LOCALE_CSV, "indice_de_saude;%.2f;;;",
                data.getKpis().indiceSaude()));

        linhas.add("");
        linhas.add("RECOMENDACOES");
        linhas.add("prioridade;recomendacao");
        for (String recomendacao : data.getRecommendations()) {
            String prioridade = recomendacao.toLowerCase(Locale.ROOT).contains("abaixo")
                    || recomendacao.toLowerCase(Locale.ROOT).contains("risco")
                    || recomendacao.toLowerCase(Locale.ROOT).contains("critico")
                    ? "ALTA" : "MEDIA";
            linhas.add(prioridade + ";" + csv(recomendacao));
        }

        linhas.add("");
        linhas.add("SERIE CONSOLIDADA PARA GRAFICOS");
        linhas.add("bloco;temperatura;umidade_do_ar;umidade_do_solo;alertas");
        for (int i = 0; i < data.getLinePoints().size(); i++) {
            PeriodData.SeriesPoint serie = data.getLinePoints().get(i);
            double alertas = i < data.getAlertPoints().size()
                    ? data.getAlertPoints().get(i).temperatura() : 0;
            linhas.add(String.format(LOCALE_CSV, "%s;%.2f;%.2f;%.2f;%.2f",
                    serie.label(), serie.temperatura(), serie.umidade(),
                    serie.umidadeSolo(), alertas));
        }

        linhas.add("");
        linhas.add("DADOS DETALHADOS");
        linhas.add("id;temperatura;umidade;umidade_solo;significado");
        for (SensorData amostra : data.getSamples()) {
            linhas.add(String.format(LOCALE_CSV, "%d;%.2f;%.2f;%.2f;%s",
                    amostra.getId() == null ? 0 : amostra.getId(),
                    amostra.getTemperatura(),
                    amostra.getUmidade(),
                    amostra.umidadeSoloOuZero(),
                    csv(amostra.getSignificado())));
        }
        Files.writeString(path, "\uFEFF" + String.join("\r\n", linhas) + "\r\n",
                StandardCharsets.UTF_8);
    }

    public void exportPdf(Path path, PeriodData data) throws IOException {
        try (PDDocument documento = new PDDocument()) {
            PDPage capa = new PDPage(PDRectangle.A4);
            documento.addPage(capa);
            try (PDPageContentStream stream = new PDPageContentStream(documento, capa)) {
                cabecalho(stream, capa, "ESTUFA SMART", "RELATORIO INTELIGENTE",
                        data.getPeriodType().getLabel());
                float y = 690;
                y = titulo(stream, y, "Resumo executivo");
                y = metadata(stream, y, "Periodo", data.getPeriodType().getLabel());
                y = metadata(stream, y, "Leituras analisadas",
                        String.valueOf(data.getSamples().size()));
                y -= 20;
                cartao(stream, 50, y - 75, 155, 75, "TEMPERATURA",
                        String.format(Locale.US, "%.2f C", data.getKpis().temperaturaMedia()));
                cartao(stream, 228, y - 75, 155, 75, "UMIDADE DO AR",
                        String.format(Locale.US, "%.2f%%", data.getKpis().umidadeMedia()));
                cartao(stream, 406, y - 75, 155, 75, "UMIDADE DO SOLO",
                        String.format(Locale.US, "%.2f%%", data.getKpis().umidadeSoloMedia()));
                y -= 110;
                y = titulo(stream, y, "Recomendacoes");
                for (String recomendacao : data.getRecommendations()) {
                    y = textoBullet(stream, capa, y, recomendacao);
                }
                y -= 8;
                y = titulo(stream, y, "Diagnostico");
                y = texto(stream, capa, y, 50, data.getSummary());
                rodape(stream, capa, 1);
            }

            PDPage grafico = new PDPage(new PDRectangle(PDRectangle.A4.getHeight(), PDRectangle.A4.getWidth()));
            documento.addPage(grafico);
            try (PDPageContentStream stream = new PDPageContentStream(documento, grafico)) {
                cabecalho(stream, grafico, "ESTUFA SMART", "EVOLUCAO DOS INDICADORES",
                        data.getPeriodType().getLabel());
                PDImageXObject imagemLinha = PDImageXObject.createFromByteArray(
                        documento, criarGraficoLinha(data), "evolucao");
                stream.drawImage(imagemLinha, 45, 155, 752, 326);
                stream.setFont(PDType1Font.HELVETICA, 9);
                stream.setNonStrokingColor(new java.awt.Color(17, 49, 40));
                stream.beginText();
                stream.newLineAtOffset(45, 130);
                stream.showText("Laranja: temperatura  |  Azul: umidade do ar  |  Verde: umidade do solo");
                stream.endText();
                rodape(stream, grafico, 2);
            }

            PDPage analise = new PDPage(PDRectangle.A4);
            documento.addPage(analise);
            try (PDPageContentStream stream = new PDPageContentStream(documento, analise)) {
                cabecalho(stream, analise, "ESTUFA SMART", "ANALISE DE ALERTAS E SAUDE",
                        data.getPeriodType().getLabel());
                PDImageXObject imagemBarras = PDImageXObject.createFromByteArray(
                        documento, criarGraficoAlertas(data), "alertas");
                stream.drawImage(imagemBarras, 45, 470, 505, 260);
                PDImageXObject imagemSaude = PDImageXObject.createFromByteArray(
                        documento, criarGraficoSaude(data), "saude");
                stream.drawImage(imagemSaude, 50, 180, 280, 200);
                titulo(stream, 370, 350, "Indicadores");
                texto(stream, analise, 338, 350,
                        String.format(Locale.US, "Tempo em faixa ideal: %.1f%%",
                                data.getKpis().tempoFaixaIdealPct()));
                texto(stream, analise, 296, 350,
                        String.format(Locale.US, "Indice de saude: %.1f",
                                data.getKpis().indiceSaude()));
                rodape(stream, analise, 3);
            }

            documento.save(path.toFile());
        }
    }

    private byte[] criarGraficoLinha(PeriodData data) throws IOException {
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        for (PeriodData.SeriesPoint ponto : data.getLinePoints()) {
            dataset.addValue(ponto.temperatura(), "Temperatura C", ponto.label());
            dataset.addValue(ponto.umidade(), "Umidade do ar %", ponto.label());
            dataset.addValue(ponto.umidadeSolo(), "Umidade do solo %", ponto.label());
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
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        ChartUtils.writeChartAsPNG(saida, chart, 1500, 650);
        return saida.toByteArray();
    }

    private byte[] criarGraficoAlertas(PeriodData data) throws IOException {
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        for (PeriodData.SeriesPoint ponto : data.getAlertPoints()) {
            dataset.addValue(ponto.temperatura(), "Alertas", ponto.label());
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

    private byte[] criarGraficoSaude(PeriodData data) throws IOException {
        double ideal = data.getKpis().tempoFaixaIdealPct();
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
        stream.setNonStrokingColor(new java.awt.Color(14, 125, 99));
        stream.addRect(0, page.getMediaBox().getHeight() - 78,
                page.getMediaBox().getWidth(), 78);
        stream.fill();
        stream.setNonStrokingColor(java.awt.Color.WHITE);
        stream.beginText();
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
        stream.setNonStrokingColor(new java.awt.Color(14, 125, 99));
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 16);
        stream.newLineAtOffset(x, y);
        stream.showText(texto);
        stream.endText();
        return y - 28;
    }

    private float metadata(PDPageContentStream stream, float y,
                           String label, String valor) throws IOException {
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 9);
        stream.setNonStrokingColor(new java.awt.Color(80, 100, 92));
        stream.newLineAtOffset(50, y);
        stream.showText(label.toUpperCase(Locale.ROOT));
        stream.endText();
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA, 11);
        stream.setNonStrokingColor(new java.awt.Color(17, 49, 40));
        stream.newLineAtOffset(170, y);
        stream.showText(valor);
        stream.endText();
        return y - 22;
    }

    private void cartao(PDPageContentStream stream, float x, float y,
                        float largura, float altura, String titulo, String valor) throws IOException {
        stream.setNonStrokingColor(java.awt.Color.WHITE);
        stream.addRect(x, y, largura, altura);
        stream.fill();
        stream.setStrokingColor(new java.awt.Color(210, 226, 216));
        stream.addRect(x, y, largura, altura);
        stream.stroke();
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 8);
        stream.setNonStrokingColor(new java.awt.Color(90, 110, 101));
        stream.newLineAtOffset(x + 12, y + 52);
        stream.showText(titulo);
        stream.endText();
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA_BOLD, 18);
        stream.setNonStrokingColor(new java.awt.Color(14, 125, 99));
        stream.newLineAtOffset(x + 12, y + 24);
        stream.showText(valor);
        stream.endText();
    }

    private float textoBullet(PDPageContentStream stream, PDPage page,
                              float y, String texto) throws IOException {
        stream.setNonStrokingColor(new java.awt.Color(14, 125, 99));
        stream.addRect(50, y - 3, 5, 5);
        stream.fill();
        return texto(stream, page, y, 64, texto);
    }

    private float texto(PDPageContentStream stream, PDPage page, float y,
                        float x, String texto) throws IOException {
        float fontSize = 10;
        float lineHeight = 14;
        float maxWidth = page.getMediaBox().getWidth() - x - 40;
        List<String> lines = new ArrayList<>();
        StringBuilder line = new StringBuilder();
        for (String word : texto.trim().split("\\s+")) {
            String candidate = line.isEmpty() ? word : line + " " + word;
            if (!line.isEmpty()
                    && PDType1Font.HELVETICA.getStringWidth(candidate) / 1000 * fontSize > maxWidth) {
                lines.add(line.toString());
                line.setLength(0);
                line.append(word);
            } else {
                if (!line.isEmpty()) line.append(' ');
                line.append(word);
            }
        }
        if (!line.isEmpty()) lines.add(line.toString());

        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA, fontSize);
        stream.setNonStrokingColor(new java.awt.Color(17, 49, 40));
        stream.newLineAtOffset(x, y);
        for (int i = 0; i < lines.size(); i++) {
            if (i > 0) stream.newLineAtOffset(0, -lineHeight);
            stream.showText(lines.get(i));
        }
        stream.endText();
        return y - lines.size() * lineHeight - 4;
    }

    private void rodape(PDPageContentStream stream, PDPage page, int pagina) throws IOException {
        stream.setStrokingColor(new java.awt.Color(210, 226, 216));
        stream.moveTo(40, 35);
        stream.lineTo(page.getMediaBox().getWidth() - 40, 35);
        stream.stroke();
        stream.beginText();
        stream.setFont(PDType1Font.HELVETICA, 8);
        stream.setNonStrokingColor(new java.awt.Color(100, 115, 108));
        stream.newLineAtOffset(40, 20);
        stream.showText("Estufa Smart  |  Gerado em "
                + LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))
                + "  |  Pagina " + pagina);
        stream.endText();
    }

    private String csv(String valor) {
        if (valor == null) return "\"\"";
        return "\"" + valor.replace("\"", "\"\"").replace("\n", " ").replace(",", " ") + "\"";
    }
}
