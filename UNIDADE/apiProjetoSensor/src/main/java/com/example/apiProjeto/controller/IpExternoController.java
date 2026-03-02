package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.IpExterno;
import com.example.apiProjeto.repository.IpExternoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/ip")
public class IpExternoController {

    @Autowired
    private IpExternoRepository repository;

    @PostMapping("/salvar")
    public IpExterno salvarNovoIp(@RequestBody String novoIp) {
        // Apaga todos os IPs anteriores
        repository.deleteAll();

        // Salva o novo IP
        IpExterno ip = new IpExterno(novoIp);
        return repository.save(ip);
    }

    @GetMapping("/atual")
    public IpExterno buscarIpAtual() {
        List<IpExterno> lista = repository.findAll();
        return lista.isEmpty() ? null : lista.get(0);
    }
}