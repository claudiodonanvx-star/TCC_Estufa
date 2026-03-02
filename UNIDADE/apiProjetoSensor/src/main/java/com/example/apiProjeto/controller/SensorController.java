package com.example.apiProjeto.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.SensorDataRepository;
@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class SensorController {

    @Autowired
    private SensorDataRepository repository;

    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        return ResponseEntity.ok("pong");
    }

    @PostMapping("/dados")
    public ResponseEntity<String> receberDados(@RequestBody SensorData dados) {
        repository.save(dados);
        System.out.println("📥 Dados recebidos:");
        System.out.println("🌡️ Temperatura: " + dados.getTemperatura());
        System.out.println("💧 Umidade: " + dados.getUmidade());
        System.out.println("🔎 Significado: " + dados.getSignificado());
        return ResponseEntity.ok("Dados salvos com sucesso");
    }

    @GetMapping("/dados")
    public List<SensorData> listarDados() {
        return repository.findAll();
    }

}
