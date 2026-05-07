package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.AlertaRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import com.example.apiProjeto.service.AlertaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class SensorController {

    private static final long START_TIME = System.currentTimeMillis();

    @Autowired
    private SensorDataRepository repository;

    @Autowired
    private AlertaRepository alertaRepository;

    @Autowired
    private AlertaService alertaService;

    @GetMapping("/ping")
    public ResponseEntity<?> ping() {
        long uptimeMs = System.currentTimeMillis() - START_TIME;
        long uptimeMin = uptimeMs / 60000;
        long totalLeituras = repository.count();
        long alertas24h = alertaRepository.countByGeradoEmAfter(LocalDateTime.now().minusHours(24));
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "versao", "1.0.0",
                "uptimeMinutos", uptimeMin,
                "totalLeituras", totalLeituras,
                "alertas24h", alertas24h
        ));
    }

    @PostMapping("/dados")
    public ResponseEntity<String> receberDados(@RequestBody SensorData dados) {
        repository.save(dados);
        System.out.println("Dados recebidos: temp=" + dados.getTemperatura()
                + " umid=" + dados.getUmidade()
                + " solo=" + dados.getUmidadeSolo());
        // Verificar alertas de forma assíncrona para não bloquear o Arduino
        Thread.ofVirtual().start(() -> alertaService.verificarEGerarAlertas(dados));
        return ResponseEntity.ok("Dados salvos com sucesso");
    }

    /**
     * Lista dados com paginação opcional.
     * ?page=0&size=50&ordem=desc (ordem=asc por padrão)
     */
    @GetMapping("/dados")
    public List<SensorData> listarDados(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(defaultValue = "asc") String ordem) {

        Sort sort = "desc".equalsIgnoreCase(ordem)
                ? Sort.by("id").descending()
                : Sort.by("id").ascending();

        if (page != null && size != null) {
            return repository.findAll(PageRequest.of(page, size, sort)).getContent();
        }
        return repository.findAll(sort);
    }

    @GetMapping("/dados/count")
    public ResponseEntity<?> count() {
        return ResponseEntity.ok(Map.of("total", repository.count()));
    }
}
