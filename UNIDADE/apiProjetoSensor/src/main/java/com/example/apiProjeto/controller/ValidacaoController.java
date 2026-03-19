package com.example.apiProjeto.controller;

import com.example.apiProjeto.dto.RespostaSensorDTO;
import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.CultivoRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class ValidacaoController {

    @Autowired
    private CultivoRepository cultivoRepository;

    @Autowired
    private SensorDataRepository sensorRepository;

    @PostMapping("/validar")
    public RespostaSensorDTO validarLeitura(@RequestBody SensorData dados) {
        Cultivo cultivo = cultivoRepository.findFirstByHabilitadaTrueOrderByIdDesc();

        String significado = "Condicao indefinida";
        int r = 255, g = 255, b = 255; // Branco por padrão

        float t = dados.getTemperatura();
        float u = dados.getUmidade();
        Float us = dados.getUmidadeSolo();

        if (cultivo == null) {
            dados.setSignificado(significado);
            sensorRepository.save(dados);
            return new RespostaSensorDTO(significado, r, g, b);
        }

        boolean tempBaixa = t < cultivo.getTemperaturaMinima();
        boolean tempAlta = t > cultivo.getTemperaturaMaxima();
        boolean umidBaixa = u < cultivo.getUmidadeMinima();
        boolean umidAlta = u > cultivo.getUmidadeMaxima();
        boolean soloBaixo = us != null && us < cultivo.getUmidadeSoloMinima();
        boolean soloAlto = us != null && us > cultivo.getUmidadeSoloMaxima();

        if (soloBaixo) {
            significado = "Solo abaixo do ideal";
            r = 255; g = 140; b = 0; // Laranja escuro
        } else if (soloAlto) {
            significado = "Solo acima do ideal";
            r = 0; g = 180; b = 255; // Azul claro
        } else if (tempBaixa && umidBaixa) {
            significado = "Ambiente seco e frio";
            r = 0; g = 0; b = 255; // Azul
        } else if (tempAlta && umidAlta) {
            significado = "Ambiente quente e umido";
            r = 255; g = 0; b = 0; // Vermelho
        } else if (tempAlta && umidBaixa) {
            significado = "Quente e seco";
            r = 255; g = 165; b = 0; // Laranja
        } else if (tempBaixa && umidAlta) {
            significado = "Frio e umido";
            r = 128; g = 0; b = 128; // Roxo
        } else if (tempAlta) {
            significado = "Quente";
            r = 255; g = 90; b = 0;
        } else if (tempBaixa) {
            significado = "Frio";
            r = 70; g = 130; b = 255;
        } else if (umidAlta) {
            significado = "Umidade alta";
            r = 0; g = 220; b = 220;
        } else if (umidBaixa) {
            significado = "Umidade baixa";
            r = 255; g = 220; b = 0;
        } else {
            significado = "Ambiente ideal";
            r = 0; g = 255; b = 0; // Verde
        }

        dados.setSignificado(significado);
        sensorRepository.save(dados);

        return new RespostaSensorDTO(significado, r, g, b);
    }
}
