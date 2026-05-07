package br.com.estufa.desktop.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class PeriodData {
    private final PeriodType periodType;
    private final List<SensorData> samples;
    private final List<SeriesPoint> linePoints;
    private final List<SeriesPoint> alertPoints;
    private final List<HeatPoint> heatPoints;
    private final Map<String, Integer> alertBreakdown;
    private final KpiMetrics kpis;
    private final String summary;
    private final List<String> recommendations;

    public PeriodData(
            PeriodType periodType,
            List<SensorData> samples,
            List<SeriesPoint> linePoints,
            List<SeriesPoint> alertPoints,
            List<HeatPoint> heatPoints,
            Map<String, Integer> alertBreakdown,
            KpiMetrics kpis,
            String summary,
            List<String> recommendations
    ) {
        this.periodType = periodType;
        this.samples = new ArrayList<>(samples);
        this.linePoints = new ArrayList<>(linePoints);
        this.alertPoints = new ArrayList<>(alertPoints);
        this.heatPoints = new ArrayList<>(heatPoints);
        this.alertBreakdown = alertBreakdown;
        this.kpis = kpis;
        this.summary = summary;
        this.recommendations = new ArrayList<>(recommendations);
    }

    public PeriodType getPeriodType() {
        return periodType;
    }

    public List<SensorData> getSamples() {
        return samples;
    }

    public List<SeriesPoint> getLinePoints() {
        return linePoints;
    }

    public List<SeriesPoint> getAlertPoints() {
        return alertPoints;
    }

    public List<HeatPoint> getHeatPoints() {
        return heatPoints;
    }

    public Map<String, Integer> getAlertBreakdown() {
        return alertBreakdown;
    }

    public KpiMetrics getKpis() {
        return kpis;
    }

    public String getSummary() {
        return summary;
    }

    public List<String> getRecommendations() {
        return recommendations;
    }

    public record SeriesPoint(String label, double temperatura, double umidade, double umidadeSolo) {}

    public record HeatPoint(int row, int col, int value) {}

    public record KpiMetrics(
            double temperaturaMedia,
            double umidadeMedia,
            double umidadeSoloMedia,
            double tempoFaixaIdealPct,
            int alertasCriticos,
            int automaticos,
            int forcados,
            double indiceSaude
    ) {}
}
