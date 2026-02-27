package com.example.apiProjeto.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.apiProjeto.model.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByLogin(String login);
}
