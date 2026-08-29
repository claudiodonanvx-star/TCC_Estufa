package com.example.apiProjeto.service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.model.SensorData;

@Service
public class AtuadorService {

    public static final int DURACAO_MANUAL_MAXIMA_SEGUNDOS = 55;

    private boolean modoAutomatico;
    private boolean bombaAutomatica;
    private boolean coolerAutomatico;
    private Instant bombaManualAte = Instant.EPOCH;
    private Instant coolerManualAte = Instant.EPOCH;

    public synchronized void atualizarLeitura(Cultivo cultivo, SensorData dados) {
        if (!modoAutomatico || cultivo == null || dados == null) {
            bombaAutomatica = false;
            coolerAutomatico = false;
            return;
        }

        Float umidadeSolo = dados.getUmidadeSolo();
        bombaAutomatica = umidadeSolo != null
                && umidadeSolo < cultivo.getUmidadeSoloMinima();
        coolerAutomatico = dados.getTemperatura() > cultivo.getTemperaturaMaxima();
    }

    public synchronized Map<String, Object> definirModoAutomatico(boolean ativo) {
        modoAutomatico = ativo;
        if (!ativo) {
            bombaAutomatica = false;
            coolerAutomatico = false;
        }
        return obterEstado();
    }

    public synchronized Map<String, Object> acionarManual(String atuador, int duracaoSegundos) {
        if (duracaoSegundos < 1 || duracaoSegundos > DURACAO_MANUAL_MAXIMA_SEGUNDOS) {
            throw new IllegalArgumentException(
                    "A duracao manual deve estar entre 1 e " + DURACAO_MANUAL_MAXIMA_SEGUNDOS + " segundos.");
        }

        Instant ate = Instant.now().plusSeconds(duracaoSegundos);
        switch (atuador.toLowerCase()) {
            case "bomba" -> bombaManualAte = ate;
            case "cooler" -> coolerManualAte = ate;
            default -> throw new IllegalArgumentException("Atuador invalido: " + atuador);
        }
        return obterEstado();
    }

    public synchronized Map<String, Object> obterEstado() {
        Instant agora = Instant.now();
        boolean bombaManual = agora.isBefore(bombaManualAte);
        boolean coolerManual = agora.isBefore(coolerManualAte);

        return Map.of(
                "modoAutomatico", modoAutomatico,
                "bombaLigada", bombaAutomatica || bombaManual,
                "coolerLigado", coolerAutomatico || coolerManual,
                "bombaManualRestanteSegundos", segundosRestantes(bombaManualAte, agora),
                "coolerManualRestanteSegundos", segundosRestantes(coolerManualAte, agora));
    }

    private long segundosRestantes(Instant ate, Instant agora) {
        return Math.max(0, Duration.between(agora, ate).toSeconds());
    }
}