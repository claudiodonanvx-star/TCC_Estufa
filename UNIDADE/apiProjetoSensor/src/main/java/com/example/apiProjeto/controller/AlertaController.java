package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.Alerta;
import com.example.apiProjeto.repository.AlertaRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/alertas")
public class AlertaController {

    @Autowired
    private AlertaRepository alertaRepository;

    @Autowired
    private SensorDataRepository sensorDataRepository;

    /** Últimos 100 alertas (mais recentes primeiro) */
    @GetMapping
    public List<Alerta> listar() {
        return alertaRepository.findTop100ByOrderByGeradoEmDesc();
    }

    /** Últimos 20 alertas CRITICOS */
    @GetMapping("/criticos")
    public List<Alerta> criticos() {
        return alertaRepository.findTop20BySeveridadeOrderByGeradoEmDesc("CRITICO");
    }

    /** Contagem nas últimas N horas */
    @GetMapping("/count")
    public ResponseEntity<?> count(@RequestParam(defaultValue = "24") int horas) {
        LocalDateTime desde = LocalDateTime.now().minusHours(horas);
        long total = alertaRepository.countByGeradoEmAfter(desde);
        long criticos = alertaRepository.countBySeveridadeAndGeradoEmAfter("CRITICO", desde);
        long atencao = alertaRepository.countBySeveridadeAndGeradoEmAfter("ATENCAO", desde);
        return ResponseEntity.ok(Map.of(
                "horas", horas,
                "total", total,
                "criticos", criticos,
                "atencao", atencao
        ));
    }
}
