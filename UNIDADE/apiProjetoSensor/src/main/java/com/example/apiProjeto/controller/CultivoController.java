package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.repository.CultivoRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class CultivoController {

    @Autowired
    private CultivoRepository cultivoRepository;

    @GetMapping("/cultivo-habilitado")
    public Cultivo getCultivoHabilitado() {
        return cultivoRepository.findFirstByHabilitadaTrueOrderByIdDesc();
    }

    @GetMapping("/cultivos")
    public List<Cultivo> listarCultivos() {
        return cultivoRepository.findAll();
    }

    @PostMapping("/cultivos")
    @ResponseStatus(HttpStatus.CREATED)
    public Cultivo criarCultivo(@Valid @RequestBody Cultivo cultivo) {
        System.out.println("🌱 POST /api/cultivos recebido");
        System.out.println("   Nome: " + cultivo.getNome());
        System.out.println("   Tipo: " + cultivo.getTipo());
        System.out.println("   Temp: " + cultivo.getTemperaturaMinima() + "°C - " + cultivo.getTemperaturaMaxima() + "°C");
        System.out.println("   Umidade: " + cultivo.getUmidadeMinima() + "% - " + cultivo.getUmidadeMaxima() + "%");
        System.out.println("   Solo: " + cultivo.getUmidadeSoloMinima() + "% - " + cultivo.getUmidadeSoloMaxima() + "%");

        if (cultivo.getTemperaturaMaxima() < cultivo.getTemperaturaMinima()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A temperatura máxima deve ser maior ou igual à mínima");
        }
        if (cultivo.getUmidadeMaxima() < cultivo.getUmidadeMinima()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A umidade máxima deve ser maior ou igual à mínima");
        }
        if (cultivo.getUmidadeSoloMaxima() < cultivo.getUmidadeSoloMinima()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A umidade do solo máxima deve ser maior ou igual à mínima");
        }

        cultivo.setHabilitada(false);
        Cultivo salvo = cultivoRepository.save(cultivo);
        System.out.println("✅ Cultivo criado com ID: " + salvo.getId());
        return salvo;
    }

    @PutMapping("/cultivos/{id}/habilitar")
    public String habilitarCultivo(@PathVariable Long id) {
        if (!cultivoRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Cultivo não encontrado com ID: " + id);
        }

        List<Cultivo> todos = cultivoRepository.findAll();
        for (Cultivo c : todos) {
            boolean habilitado = c.getId().equals(id);
            if (c.isHabilitada() != habilitado) {
                c.setHabilitada(habilitado);
                cultivoRepository.save(c);
            }
        }
        return "Cultivo atualizado com sucesso";
    }

    @DeleteMapping("/cultivos/{id}")
    public ResponseEntity<?> removerCultivo(@PathVariable Long id) {
        if (!cultivoRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Cultivo não encontrado com ID: " + id);
        }

        cultivoRepository.deleteById(id);
        return ResponseEntity.ok().body(Map.of("mensagem", "Cultivo removido com sucesso"));
    }
}
