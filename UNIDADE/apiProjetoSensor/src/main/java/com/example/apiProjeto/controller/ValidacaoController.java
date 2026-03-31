package com.example.apiProjeto.controller;

import com.example.apiProjeto.dto.RespostaSensorDTO;
import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.CultivoRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class ValidacaoController {

    private static final Duration TEMPO_ALERTA_SOLO = Duration.ofMinutes(5);
    private static final String MSG_SOLO_BAIXO = "Solo abaixo do ideal";
    private static final String MSG_ALERTA_SOLO = "Solo abaixo do ideal (ALERTA: seco apos 5 minutos de irrigacao)";

    private final Map<Long, LocalDateTime> soloSecoDesde = new ConcurrentHashMap<>();

    @Autowired
    private CultivoRepository cultivoRepository;

    @Autowired
    private SensorDataRepository sensorRepository;

    @PostMapping("/validar")
    public RespostaSensorDTO validarLeitura(@RequestBody SensorData dados) {
        Cultivo cultivo = cultivoRepository.findFirstByHabilitadaTrueOrderByIdDesc();

        String significado = "Condicao indefinida";
        int r = 255, g = 255, b = 255; // Branco por padrão
        boolean alerta = false;

        float t = dados.getTemperatura();
        float u = dados.getUmidade();
        Float us = dados.getUmidadeSolo();

        if (cultivo == null) {
            dados.setSignificado(significado);
            sensorRepository.save(dados);
            return new RespostaSensorDTO(significado, r, g, b, alerta);
        }

        boolean tempBaixa = t < cultivo.getTemperaturaMinima();
        boolean tempAlta = t > cultivo.getTemperaturaMaxima();
        boolean umidBaixa = u < cultivo.getUmidadeMinima();
        boolean umidAlta = u > cultivo.getUmidadeMaxima();
        boolean soloBaixo = us != null && us < cultivo.getUmidadeSoloMinima();
        boolean soloAlto = us != null && us > cultivo.getUmidadeSoloMaxima();

        if (soloBaixo) {
            Long cultivoId = cultivo.getId() != null ? cultivo.getId() : -1L;
            LocalDateTime agora = LocalDateTime.now();
            LocalDateTime inicioSecura = soloSecoDesde.computeIfAbsent(cultivoId, id -> agora);

            if (!Duration.between(inicioSecura, agora).minus(TEMPO_ALERTA_SOLO).isNegative()) {
                significado = MSG_ALERTA_SOLO;
                r = 255; g = 140; b = 0; // Mantém comando de irrigação
                alerta = true;
            } else {
                significado = MSG_SOLO_BAIXO;
                r = 255; g = 140; b = 0; // Laranja escuro para iniciar irrigação
            }
        } else if (soloAlto) {
            removerEstadoSecura(cultivo.getId());
            significado = "Solo acima do ideal";
            r = 0; g = 180; b = 255; // Azul claro
        } else if (tempBaixa && umidBaixa) {
            removerEstadoSecura(cultivo.getId());
            significado = "Ambiente seco e frio";
            r = 0; g = 0; b = 255; // Azul
        } else if (tempAlta && umidAlta) {
            removerEstadoSecura(cultivo.getId());
            significado = "Ambiente quente e umido";
            r = 255; g = 0; b = 0; // Vermelho
        } else if (tempAlta && umidBaixa) {
            removerEstadoSecura(cultivo.getId());
            significado = "Quente e seco";
            r = 255; g = 165; b = 0; // Laranja
        } else if (tempBaixa && umidAlta) {
            removerEstadoSecura(cultivo.getId());
            significado = "Frio e umido";
            r = 128; g = 0; b = 128; // Roxo
        } else if (tempAlta) {
            removerEstadoSecura(cultivo.getId());
            significado = "Quente";
            r = 255; g = 90; b = 0;
        } else if (tempBaixa) {
            removerEstadoSecura(cultivo.getId());
            significado = "Frio";
            r = 70; g = 130; b = 255;
        } else if (umidAlta) {
            removerEstadoSecura(cultivo.getId());
            significado = "Umidade alta";
            r = 0; g = 220; b = 220;
        } else if (umidBaixa) {
            removerEstadoSecura(cultivo.getId());
            significado = "Umidade baixa";
            r = 255; g = 220; b = 0;
        } else {
            removerEstadoSecura(cultivo.getId());
            significado = "Ambiente ideal";
            r = 0; g = 255; b = 0; // Verde
        }

        dados.setSignificado(significado);
        sensorRepository.save(dados);

        return new RespostaSensorDTO(significado, r, g, b, alerta);
    }

    private void removerEstadoSecura(Long cultivoId) {
        Long id = cultivoId != null ? cultivoId : -1L;
        soloSecoDesde.remove(id);
    }
}
