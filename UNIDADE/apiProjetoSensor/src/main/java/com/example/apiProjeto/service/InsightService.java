package com.example.apiProjeto.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.SensorDataRepository;

@Service
public class InsightService {

    private final SensorDataRepository repository;

    public InsightService(SensorDataRepository repository) {
        this.repository = repository;
    }

    public Map<String, Object> gerarInsights(int limite) {
        int tamanho = Math.max(10, Math.min(limite, 200));
        List<SensorData> amostras = new ArrayList<>(repository.findAll(
                PageRequest.of(0, tamanho, Sort.by(Sort.Direction.DESC, "coletadoEm"))).getContent());
        amostras.sort(Comparator.comparing(SensorData::getColetadoEm,
                Comparator.nullsLast(Comparator.naturalOrder())));

        if (amostras.isEmpty()) {
            return Map.of("amostras", 0, "insights", List.of("Ainda não há histórico suficiente para análise."));
        }

        double temperaturaMedia = amostras.stream().mapToDouble(SensorData::getTemperatura).average().orElse(0);
        double umidadeMedia = amostras.stream().mapToDouble(SensorData::getUmidade).average().orElse(0);
        double soloMedia = amostras.stream().filter(s -> s.getUmidadeSolo() != null)
                .mapToDouble(s -> s.getUmidadeSolo()).average().orElse(0);
        SensorData primeira = amostras.get(0);
        SensorData ultima = amostras.get(amostras.size() - 1);
        double tendenciaTemperatura = ultima.getTemperatura() - primeira.getTemperatura();
        double tendenciaUmidade = ultima.getUmidade() - primeira.getUmidade();

        List<String> insights = new ArrayList<>();
        if (soloMedia < 35) {
            insights.add(String.format("Umidade média do solo baixa (%.1f%%): considere acionar a irrigação.", soloMedia));
        } else if (soloMedia > 80) {
            insights.add(String.format("Umidade média do solo elevada (%.1f%%): verifique drenagem e risco de excesso.", soloMedia));
        }
        if (Math.abs(tendenciaTemperatura) >= 2) {
            insights.add(String.format("Tendência de temperatura %s (%.1f °C no período).",
                    tendenciaTemperatura > 0 ? "de alta" : "de queda", Math.abs(tendenciaTemperatura)));
        }
        if (Math.abs(tendenciaUmidade) >= 8) {
            insights.add(String.format("A umidade do ar apresenta variação relevante de %.1f pontos percentuais.",
                    Math.abs(tendenciaUmidade)));
        }
        if (insights.isEmpty()) {
            insights.add("As variáveis analisadas permanecem estáveis no histórico recente.");
        }

        Map<String, Object> resultado = new LinkedHashMap<>();
        resultado.put("amostras", amostras.size());
        resultado.put("medias", Map.of("temperatura", temperaturaMedia, "umidade", umidadeMedia, "umidadeSolo", soloMedia));
        resultado.put("tendencias", Map.of("temperatura", tendenciaTemperatura, "umidade", tendenciaUmidade));
        resultado.put("insights", insights);
        resultado.put("metodo", "médias móveis e comparação entre início e fim da janela histórica");
        return resultado;
    }
}