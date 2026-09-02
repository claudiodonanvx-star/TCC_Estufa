package com.example.apiProjeto.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.apiProjeto.service.AtuadorService;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/atuadores")
public class AtuadorController {

    private final AtuadorService atuadorService;

    public AtuadorController(AtuadorService atuadorService) {
        this.atuadorService = atuadorService;
    }

    @GetMapping
    public Map<String, Object> obterEstado() {
        return atuadorService.obterEstado();
    }

    @PutMapping("/modo")
    public Map<String, Object> definirModo(@RequestBody Map<String, Boolean> comando) {
        return atuadorService.definirModoAutomatico(Boolean.TRUE.equals(comando.get("modoAutomatico")));
    }

    @PostMapping("/{atuador}/acionar")
    public ResponseEntity<?> acionarManual(
            @PathVariable String atuador,
            @RequestBody Map<String, Integer> comando) {
        try {
            int duracaoPadrao;
            if ("temperatura".equalsIgnoreCase(atuador)) {
                duracaoPadrao = AtuadorService.DURACAO_AQUECEDOR_MAXIMA_SEGUNDOS;
            } else if ("bomba".equalsIgnoreCase(atuador)) {
                duracaoPadrao = AtuadorService.DURACAO_BOMBA_MAXIMA_SEGUNDOS;
            } else {
                duracaoPadrao = AtuadorService.DURACAO_MANUAL_MAXIMA_SEGUNDOS;
            }
            int duracaoSegundos = comando.getOrDefault("duracaoSegundos", duracaoPadrao);
            return ResponseEntity.ok(atuadorService.acionarManual(atuador, duracaoSegundos));
        } catch (IllegalArgumentException erro) {
            return ResponseEntity.badRequest().body(Map.of("erro", erro.getMessage()));
        }
    }
}