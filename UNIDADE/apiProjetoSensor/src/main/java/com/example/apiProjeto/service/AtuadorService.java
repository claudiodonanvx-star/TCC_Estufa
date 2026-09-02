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
    // Aquecedor fica ligado por menos tempo que os demais reles por seguranca.
    public static final int DURACAO_AQUECEDOR_MAXIMA_SEGUNDOS = 35;
    // Bomba fica ligada por menos tempo para nao drenar a agua rapido demais.
    public static final int DURACAO_BOMBA_MAXIMA_SEGUNDOS = 15;

    private boolean modoAutomatico;
    private boolean bombaAutomatica;
    private boolean coolerAutomatico;
    private boolean temperaturaAutomatica;
    private Instant bombaManualAte = Instant.EPOCH;
    private Instant coolerManualAte = Instant.EPOCH;
    private Instant temperaturaManualAte = Instant.EPOCH;

    public synchronized void atualizarLeitura(Cultivo cultivo, SensorData dados) {
        if (!modoAutomatico || cultivo == null || dados == null) {
            bombaAutomatica = false;
            coolerAutomatico = false;
            temperaturaAutomatica = false;
            return;
        }

        Float umidadeSolo = dados.getUmidadeSolo();
        bombaAutomatica = umidadeSolo != null
                && umidadeSolo < cultivo.getUmidadeSoloMinima();
        coolerAutomatico = dados.getTemperatura() > cultivo.getTemperaturaMaxima();
        temperaturaAutomatica = dados.getTemperatura() < cultivo.getTemperaturaMinima();
    }

    public synchronized Map<String, Object> definirModoAutomatico(boolean ativo) {
        modoAutomatico = ativo;
        if (!ativo) {
            bombaAutomatica = false;
            coolerAutomatico = false;
            temperaturaAutomatica = false;
        }
        return obterEstado();
    }

    public synchronized Map<String, Object> acionarManual(String atuador, int duracaoSegundos) {
        String chave = atuador.toLowerCase();
        int duracaoMaxima = switch (chave) {
            case "temperatura" -> DURACAO_AQUECEDOR_MAXIMA_SEGUNDOS;
            case "bomba" -> DURACAO_BOMBA_MAXIMA_SEGUNDOS;
            default -> DURACAO_MANUAL_MAXIMA_SEGUNDOS;
        };
        if (duracaoSegundos < 1 || duracaoSegundos > duracaoMaxima) {
            throw new IllegalArgumentException(
                    "A duracao manual deve estar entre 1 e " + duracaoMaxima + " segundos.");
        }

        Instant ate = Instant.now().plusSeconds(duracaoSegundos);
        switch (chave) {
            case "bomba" -> bombaManualAte = ate;
            case "cooler" -> coolerManualAte = ate;
            case "temperatura" -> temperaturaManualAte = ate;
            default -> throw new IllegalArgumentException("Atuador invalido: " + atuador);
        }
        return obterEstado();
    }

    public synchronized Map<String, Object> obterEstado() {
        Instant agora = Instant.now();
        boolean bombaManual = agora.isBefore(bombaManualAte);
        boolean coolerManual = agora.isBefore(coolerManualAte);
        boolean temperaturaManual = agora.isBefore(temperaturaManualAte);

        return Map.of(
                "modoAutomatico", modoAutomatico,
                "bombaLigada", bombaAutomatica || bombaManual,
                "coolerLigado", coolerAutomatico || coolerManual,
                "temperaturaLigada", temperaturaAutomatica || temperaturaManual,
                "bombaManualRestanteSegundos", segundosRestantes(bombaManualAte, agora),
                "coolerManualRestanteSegundos", segundosRestantes(coolerManualAte, agora),
                "temperaturaManualRestanteSegundos", segundosRestantes(temperaturaManualAte, agora));
    }

    private long segundosRestantes(Instant ate, Instant agora) {
        return Math.max(0, Duration.between(agora, ate).toSeconds());
    }
}