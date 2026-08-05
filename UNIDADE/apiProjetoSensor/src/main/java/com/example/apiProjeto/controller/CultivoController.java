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
        return cultivoRepository.findFirstByHabilitadaTrueOrderByIdDesc();
    }

    @GetMapping("/cultivos")
    public List<Cultivo> listarCultivos() {
        return cultivoRepository.findAll();
    }

    @PostMapping("/cultivos")
    public Cultivo criarCultivo(@RequestBody Cultivo cultivo) {
        System.out.println("🌱 POST /api/cultivos recebido");
        System.out.println("   Nome: " + cultivo.getNome());
        System.out.println("   Tipo: " + cultivo.getTipo());
        System.out.println("   Temp: " + cultivo.getTemperaturaMinima() + "°C - " + cultivo.getTemperaturaMaxima() + "°C");
        System.out.println("   Umidade: " + cultivo.getUmidadeMinima() + "% - " + cultivo.getUmidadeMaxima() + "%");
        System.out.println("   Solo: " + cultivo.getUmidadeSoloMinima() + "% - " + cultivo.getUmidadeSoloMaxima() + "%");
        
        // Validação básica
        if (cultivo.getNome() == null || cultivo.getNome().trim().isEmpty()) {
            throw new IllegalArgumentException("Nome do cultivo é obrigatório");
        }
        if (cultivo.getTipo() == null || cultivo.getTipo().trim().isEmpty()) {
            throw new IllegalArgumentException("Tipo do cultivo é obrigatório");
        }
        
        cultivo.setHabilitada(false);
        Cultivo salvo = cultivoRepository.save(cultivo);
        System.out.println("✅ Cultivo criado com ID: " + salvo.getId());
        return salvo;
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
