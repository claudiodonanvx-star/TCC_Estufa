package br.com.estufa.desktop.service;

import br.com.estufa.desktop.model.PeriodData;
import br.com.estufa.desktop.model.SensorData;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class ExportService {

    public void exportCsv(Path path, PeriodData data) throws IOException {
        List<String> lines = new ArrayList<>();
        lines.add("periodo,temperatura_media,umidade_media,umidade_solo_media,tempo_ideal_pct,alertas_criticos,indice_saude");
        lines.add(String.format(Locale.US, "%s,%.2f,%.2f,%.2f,%.2f,%d,%.2f",
                data.getPeriodType().getLabel(),
                data.getKpis().temperaturaMedia(),
                data.getKpis().umidadeMedia(),
                data.getKpis().umidadeSoloMedia(),
                data.getKpis().tempoFaixaIdealPct(),
                data.getKpis().alertasCriticos(),
                data.getKpis().indiceSaude()));

        lines.add("");
        lines.add("id,temperatura,umidade,umidade_solo,significado");
        for (SensorData sample : data.getSamples().stream().limit(1000).toList()) {
            lines.add(String.format(Locale.US, "%d,%.2f,%.2f,%.2f,%s",
                    sample.getId() == null ? 0 : sample.getId(),
                    sample.getTemperatura(),
                    sample.getUmidade(),
                    sample.umidadeSoloOuZero(),
                    sanitize(sample.getSignificado())));
        }

        Files.write(path, lines, StandardCharsets.UTF_8);
    }

    public void exportPdf(Path path, PeriodData data) throws IOException {
        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage();
            document.addPage(page);

            try (PDPageContentStream content = new PDPageContentStream(document, page)) {
                float y = 760;
                content.beginText();
                content.setFont(PDType1Font.HELVETICA_BOLD, 16);
                content.newLineAtOffset(40, y);
                content.showText("Relatorio Inteligente - " + data.getPeriodType().getLabel());
                content.endText();

                y -= 30;
                y = writeLine(content, y, "Resumo:");
                y = writeLine(content, y, data.getSummary());
                y -= 8;

                y = writeLine(content, y, String.format(Locale.US, "Temperatura media: %.2f", data.getKpis().temperaturaMedia()));
                y = writeLine(content, y, String.format(Locale.US, "Umidade media: %.2f", data.getKpis().umidadeMedia()));
                y = writeLine(content, y, String.format(Locale.US, "Umidade do solo media: %.2f", data.getKpis().umidadeSoloMedia()));
                y = writeLine(content, y, String.format(Locale.US, "Tempo em faixa ideal: %.2f%%", data.getKpis().tempoFaixaIdealPct()));
                y = writeLine(content, y, String.format(Locale.US, "Alertas criticos: %d", data.getKpis().alertasCriticos()));
                y = writeLine(content, y, String.format(Locale.US, "Indice de saude: %.2f", data.getKpis().indiceSaude()));
                y -= 8;

                y = writeLine(content, y, "Recomendacoes:");
                for (String recommendation : data.getRecommendations()) {
                    y = writeLine(content, y, "- " + recommendation);
                }

                y -= 8;
                y = writeLine(content, y, "Observacao: periodos estimados por janela de amostras (API atual sem timestamp em /api/dados).");
            }

            document.save(path.toFile());
        }
    }

    private float writeLine(PDPageContentStream content, float y, String line) throws IOException {
        content.beginText();
        content.setFont(PDType1Font.HELVETICA, 11);
        content.newLineAtOffset(40, y);
        content.showText(line.length() > 110 ? line.substring(0, 110) : line);
        content.endText();
        return y - 16;
    }

    private String sanitize(String value) {
        if (value == null) {
            return "";
        }
        return value.replace(",", " ").replace("\n", " ").trim();
    }
}
