package com.example.apiProjeto.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.apiProjeto.model.ClientePendente;
import com.example.apiProjeto.model.StatusCadastro;

public interface ClientePendenteRepository extends JpaRepository<ClientePendente, Long> {
    boolean existsByCpfAndStatusCadastro(String cpf, StatusCadastro statusCadastro);
    Optional<ClientePendente> findTopByCpfOrderByIdDesc(String cpf);
    List<ClientePendente> findByStatusCadastroOrderByIdAsc(StatusCadastro statusCadastro);
    long countByStatusCadastro(StatusCadastro statusCadastro);
}
