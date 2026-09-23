package com.example.apiProjeto.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.apiProjeto.service.ConsultaBotanicaService;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/ia")
public class ConsultaBotanicaController {

    private final ConsultaBotanicaService service;

    public ConsultaBotanicaController(ConsultaBotanicaService service) {
        this.service = service;
    }

    @PostMapping("/consulta-planta")
    public ResponseEntity<Map<String, Object>> consultar(@RequestBody Map<String, Object> dados) {
        String planta = texto(dados.get("planta"));
        String pergunta = texto(dados.get("pergunta"));
        Double umidade = numero(dados.get("umidadeAtual"));
        Double temperatura = numero(dados.get("temperaturaAtual"));
        if (pergunta.isBlank() && planta.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("mensagem", "Informe a planta ou a pergunta."));
        }
        return ResponseEntity.ok(service.consultar(planta, pergunta, umidade, temperatura));
    }

    private String texto(Object valor) {
        return valor == null ? "" : valor.toString().trim();
    }

    private Double numero(Object valor) {
        if (valor instanceof Number numero) {
            return numero.doubleValue();
        }
        try {
            return valor == null ? null : Double.valueOf(valor.toString());
        } catch (NumberFormatException erro) {
            return null;
        }
    }
}