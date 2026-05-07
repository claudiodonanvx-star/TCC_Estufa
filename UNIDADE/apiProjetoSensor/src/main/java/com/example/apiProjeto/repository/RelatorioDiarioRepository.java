package com.example.apiProjeto.repository;

import com.example.apiProjeto.model.RelatorioDiario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface RelatorioDiarioRepository extends JpaRepository<RelatorioDiario, Long> {

    Optional<RelatorioDiario> findByDataRef(LocalDate dataRef);

    List<RelatorioDiario> findByDataRefBetweenOrderByDataRef(LocalDate inicio, LocalDate fim);
}
