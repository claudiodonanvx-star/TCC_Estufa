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
        Cultivo cultivo = cultivoRepository.findByHabilitadaTrue();

        String significado = "Condição indefinida";
        int r = 255, g = 255, b = 255; // Branco por padrão

        float t = dados.getTemperatura();
        float u = dados.getUmidade();

        boolean tempBaixa = t < cultivo.getTemperaturaMinima();
        boolean tempAlta = t > cultivo.getTemperaturaMaxima();
        boolean umidBaixa = u < cultivo.getUmidadeMinima();
        boolean umidAlta = u > cultivo.getUmidadeMaxima();

        if (tempBaixa && umidBaixa) {
            significado = "Ambiente seco e frio";
            r = 0; g = 0; b = 255; // Azul
        } else if (!tempBaixa && !tempAlta && !umidBaixa && !umidAlta) {
            significado = "Ambiente ideal";
            r = 0; g = 255; b = 0; // Verde
        } else if (tempAlta && umidAlta) {
            significado = "Ambiente quente e úmido";
            r = 255; g = 0; b = 0; // Vermelho
        } else if (tempAlta && umidBaixa) {
            significado = "Quente e seco";
            r = 255; g = 165; b = 0; // Laranja
        } else if (tempBaixa && umidAlta) {
            significado = "Frio e úmido";
            r = 128; g = 0; b = 128; // Roxo
        }

        dados.setSignificado(significado);
        sensorRepository.save(dados);

        return new RespostaSensorDTO(significado, r, g, b);
    }
}
