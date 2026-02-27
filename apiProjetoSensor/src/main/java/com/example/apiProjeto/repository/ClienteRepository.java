package com.example.apiProjeto.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.apiProjeto.model.Cliente;

public interface ClienteRepository extends JpaRepository<Cliente, Long> {
        boolean existsByCpf(String cpf);
        Optional<Cliente> findByCpf(String cpf);
    }