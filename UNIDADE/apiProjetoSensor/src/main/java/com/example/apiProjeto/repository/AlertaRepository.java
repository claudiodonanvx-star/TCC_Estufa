package com.example.apiProjeto.repository;

import com.example.apiProjeto.model.Alerta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface AlertaRepository extends JpaRepository<Alerta, Long> {

    List<Alerta> findTop100ByOrderByGeradoEmDesc();

    List<Alerta> findTop20BySeveridadeOrderByGeradoEmDesc(String severidade);

    long countByGeradoEmAfter(LocalDateTime desde);

    long countBySeveridadeAndGeradoEmAfter(String severidade, LocalDateTime desde);
}
