package com.example.apiProjeto.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Health check controller para manter a API ativa no Render.
 * Evita que a aplicação hiberne/caia por inatividade.
 */
@RestController
@RequestMapping("/api")
public class HealthController {

    /**
     * Endpoint simples de health check.
     * Retorna status da API e timestamp para confirmar que está ativa.
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", LocalDateTime.now());
        response.put("message", "API está ativa e respondendo");
        return response;
    }

    /**
     * Alias para /health - mais curto para ping frequente.
     */
    @GetMapping("/ping")
    public Map<String, Object> ping() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("timestamp", LocalDateTime.now());
        return response;
    }
}
