package com.example.apiProjeto.service;

import com.example.apiProjeto.model.RelatorioDiario;
import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.RelatorioDiarioRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.OptionalDouble;

@Service
public class ConsolidacaoService {

    @Autowired
    private SensorDataRepository sensorDataRepository;

    @Autowired
    private RelatorioDiarioRepository relatorioDiarioRepository;

    /**
     * Consolida o dia anterior (D-1) na tabela relatorio_diario.
     * Idempotente: faz upsert pelo campo data_ref.
     */
    @Transactional
    public String consolidarD1() {
        LocalDate ontem = LocalDate.now().minusDays(1);
        return consolidarDia(ontem);
    }

    /**
     * Consolida um dia específico.
     */
    @Transactional
    public String consolidarDia(LocalDate data) {
        LocalDateTime inicio = data.atStartOfDay();
        LocalDateTime fim = data.atTime(LocalTime.MAX);

        List<SensorData> leituras = sensorDataRepository.findByPeriodo(inicio, fim);

        if (leituras.isEmpty()) {
            return "Sem leituras para " + data + ". Nenhuma consolidação realizada.";
        }

        OptionalDouble tempMedia  = leituras.stream().mapToDouble(SensorData::getTemperatura).average();
        double tempMin  = leituras.stream().mapToDouble(SensorData::getTemperatura).min().orElse(0);
        double tempMax  = leituras.stream().mapToDouble(SensorData::getTemperatura).max().orElse(0);

        OptionalDouble umidadeMedia = leituras.stream().mapToDouble(SensorData::getUmidade).average();
        double umidMin  = leituras.stream().mapToDouble(SensorData::getUmidade).min().orElse(0);
        double umidMax  = leituras.stream().mapToDouble(SensorData::getUmidade).max().orElse(0);

        OptionalDouble soloMedia = leituras.stream().mapToDouble(s -> s.getUmidadeSolo() == null ? 0.0 : s.getUmidadeSolo()).average();
        double soloMin  = leituras.stream().mapToDouble(s -> s.getUmidadeSolo() == null ? 0.0 : s.getUmidadeSolo()).min().orElse(0);
        double soloMax  = leituras.stream().mapToDouble(s -> s.getUmidadeSolo() == null ? 0.0 : s.getUmidadeSolo()).max().orElse(0);

        RelatorioDiario relatorio = relatorioDiarioRepository
                .findByDataRef(data)
                .orElse(new RelatorioDiario());

        relatorio.setDataRef(data);
        relatorio.setTempMedia(tempMedia.orElse(0));
        relatorio.setTempMinima(tempMin);
        relatorio.setTempMaxima(tempMax);
        relatorio.setUmidadeMedia(umidadeMedia.orElse(0));
        relatorio.setUmidadeMinima(umidMin);
        relatorio.setUmidadeMaxima(umidMax);
        relatorio.setSoloMedia(soloMedia.orElse(0));
        relatorio.setSoloMinima(soloMin);
        relatorio.setSoloMaxima(soloMax);
        relatorio.setTotalLeituras(leituras.size());

        relatorioDiarioRepository.save(relatorio);

        return "Consolidado " + data + ": " + leituras.size() + " leituras processadas.";
    }

    /**
     * Remove leituras brutas com mais de retencaoDias dias.
     * Executa em lote para evitar travamento do banco.
     */
    @Transactional
    public String limparAntigos(int retencaoDias) {
        LocalDateTime corte = LocalDateTime.now().minusDays(retencaoDias);
        int removidos = sensorDataRepository.deleteAnteriorA(corte);
        return "Limpeza: " + removidos + " registros brutos anteriores a " + corte.toLocalDate() + " removidos.";
    }
}
