package br.com.estufa.desktop.service;

import br.com.estufa.desktop.model.Cultivo;
import br.com.estufa.desktop.model.PeriodData;
import br.com.estufa.desktop.model.PeriodType;
import br.com.estufa.desktop.model.SensorData;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

public class AnalyticsService {

    public PeriodData buildPeriodData(List<SensorData> allSamples, Cultivo cultivo, PeriodType period) {
        List<SensorData> samples = sliceByPeriod(allSamples, period);

        if (samples.isEmpty()) {
            return new PeriodData(
                    period,
                    List.of(),
                    List.of(),
                    List.of(),
                    List.of(),
                    Map.of(),
                    new PeriodData.KpiMetrics(0, 0, 0, 0, 0, 0, 0, 0),
                    "Sem dados para o periodo selecionado.",
                    List.of("Verifique se a API esta recebendo leituras em /api/dados.")
            );
        }

        int bucketCount = Math.min(period.getBuckets(), samples.size());
        List<List<SensorData>> buckets = splitInBuckets(samples, bucketCount);

        List<PeriodData.SeriesPoint> line = new ArrayList<>();
        List<PeriodData.SeriesPoint> alerts = new ArrayList<>();
        List<PeriodData.HeatPoint> heat = new ArrayList<>();

        int totalAlerts = 0;
        int automaticos = 0;
        int forcados = 0;
        int inRange = 0;

        Map<String, Integer> breakdown = new HashMap<>();

        for (int i = 0; i < buckets.size(); i++) {
            List<SensorData> bucket = buckets.get(i);
            double tempMedia = bucket.stream().mapToDouble(SensorData::getTemperatura).average().orElse(0);
            double umidadeMedia = bucket.stream().mapToDouble(SensorData::getUmidade).average().orElse(0);
            double soloMedia = bucket.stream().mapToDouble(SensorData::umidadeSoloOuZero).average().orElse(0);

            int alertsBucket = 0;
            for (SensorData s : bucket) {
                boolean tempOk = inRange(s.getTemperatura(), cultivo == null ? 0 : cultivo.getTemperaturaMinima(), cultivo == null ? 100 : cultivo.getTemperaturaMaxima());
                boolean umidadeOk = inRange(s.getUmidade(), cultivo == null ? 0 : cultivo.getUmidadeMinima(), cultivo == null ? 100 : cultivo.getUmidadeMaxima());
                boolean soloOk = inRange(s.umidadeSoloOuZero(), cultivo == null ? 0 : cultivo.getUmidadeSoloMinima(), cultivo == null ? 100 : cultivo.getUmidadeSoloMaxima());

                if (tempOk && umidadeOk && soloOk) {
                    inRange++;
                } else {
                    alertsBucket++;
                    totalAlerts++;
                }

                String sig = s.getSignificado() == null || s.getSignificado().isBlank() ? "Sem classificacao" : s.getSignificado();
                breakdown.merge(sig, 1, Integer::sum);

                if (sig.toLowerCase(Locale.ROOT).contains("automatic")) {
                    automaticos++;
                }
                if (sig.toLowerCase(Locale.ROOT).contains("forcad")) {
                    forcados++;
                }
            }

            String label = "B" + (i + 1);
            line.add(new PeriodData.SeriesPoint(label, tempMedia, umidadeMedia, soloMedia));
            alerts.add(new PeriodData.SeriesPoint(label, alertsBucket, 0, 0));

            int row = i / 7;
            int col = i % 7;
            heat.add(new PeriodData.HeatPoint(row, col, alertsBucket));
        }

        double tempGeral = samples.stream().mapToDouble(SensorData::getTemperatura).average().orElse(0);
        double umidadeGeral = samples.stream().mapToDouble(SensorData::getUmidade).average().orElse(0);
        double soloGeral = samples.stream().mapToDouble(SensorData::umidadeSoloOuZero).average().orElse(0);
        double idealPct = samples.isEmpty() ? 0 : (inRange * 100.0) / samples.size();
        double saude = Math.max(0, Math.min(100, idealPct - (totalAlerts * 0.05)));

        PeriodData.KpiMetrics kpis = new PeriodData.KpiMetrics(
                tempGeral,
                umidadeGeral,
                soloGeral,
                idealPct,
                totalAlerts,
                automaticos,
                forcados,
                saude
        );

        String summary = buildSummary(period, kpis, breakdown);
        List<String> recommendations = buildRecommendations(kpis, breakdown);

        Map<String, Integer> topBreakdown = breakdown.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                .limit(6)
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (a, b) -> a, java.util.LinkedHashMap::new));

        return new PeriodData(period, samples, line, alerts, heat, topBreakdown, kpis, summary, recommendations);
    }

    private List<SensorData> sliceByPeriod(List<SensorData> all, PeriodType period) {
        if (all == null || all.isEmpty()) {
            return List.of();
        }
        List<SensorData> sorted = all.stream()
                .sorted(Comparator.comparing(s -> s.getId() == null ? 0L : s.getId()))
                .toList();

        int start = Math.max(0, sorted.size() - period.getSampleWindow());
        return new ArrayList<>(sorted.subList(start, sorted.size()));
    }

    private List<List<SensorData>> splitInBuckets(List<SensorData> samples, int buckets) {
        List<List<SensorData>> result = new ArrayList<>();
        if (samples.isEmpty() || buckets <= 0) {
            return result;
        }

        int bucketSize = Math.max(1, samples.size() / buckets);
        for (int i = 0; i < samples.size(); i += bucketSize) {
            result.add(samples.subList(i, Math.min(samples.size(), i + bucketSize)));
        }
        return result;
    }

    private boolean inRange(double value, double min, double max) {
        return value >= min && value <= max;
    }

    private String buildSummary(PeriodType period, PeriodData.KpiMetrics kpis, Map<String, Integer> breakdown) {
        String principalRisco = breakdown.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("Nenhum risco relevante");

        return String.format(Locale.US,
                "No periodo %s, a estufa ficou %.1f%% do tempo em faixa ideal. " +
                        "Foram detectados %d alertas criticos. Risco mais recorrente: %s.",
                period.getLabel().toLowerCase(Locale.ROOT),
                kpis.tempoFaixaIdealPct(),
                kpis.alertasCriticos(),
                principalRisco
        );
    }

    private List<String> buildRecommendations(PeriodData.KpiMetrics kpis, Map<String, Integer> breakdown) {
        List<String> recs = new ArrayList<>();

        if (kpis.tempoFaixaIdealPct() < 70) {
            recs.add("Tempo em faixa ideal abaixo de 70%. Ajustar parametros de controle de temperatura e irrigacao.");
        }
        if (kpis.forcados() > kpis.automaticos()) {
            recs.add("Acionamentos forcados acima dos automaticos. Revisar regras de automacao e sensores.");
        }

        String solo = breakdown.keySet().stream()
                .filter(k -> k.toLowerCase(Locale.ROOT).contains("solo"))
                .findFirst()
                .orElse(null);

        if (solo != null) {
            recs.add("Ocorrencias de solo recorrentes detectadas. Antecipar irrigacao preventiva nos horarios criticos.");
        }

        if (kpis.alertasCriticos() > 0 && recs.size() < 3) {
            recs.add("Monitorar alertas em janela curta e validar manutencao preventiva dos atuadores.");
        }

        if (recs.isEmpty()) {
            recs.add("Operacao estavel. Manter configuracoes atuais e acompanhar tendencia semanal.");
        }

        return recs.stream().limit(3).toList();
    }
}
