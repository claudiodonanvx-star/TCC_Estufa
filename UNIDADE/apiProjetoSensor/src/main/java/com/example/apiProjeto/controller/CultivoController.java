package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.repository.CultivoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class CultivoController {

    @Autowired
    private CultivoRepository cultivoRepository;

    @GetMapping("/cultivo-habilitado")
    public Cultivo getCultivoHabilitado() {
        return cultivoRepository.findByHabilitadaTrue();
    }

    @GetMapping("/cultivos")
    public List<Cultivo> listarCultivos() {
        return cultivoRepository.findAll();
    }

    @PutMapping("/cultivos/{id}/habilitar")
    public String habilitarCultivo(@PathVariable Long id) {
        List<Cultivo> todos = cultivoRepository.findAll();
        for (Cultivo c : todos) {
            c.setHabilitada(c.getId().equals(id));
            cultivoRepository.save(c);
        }
        return "Cultivo atualizado com sucesso";
    }
}
