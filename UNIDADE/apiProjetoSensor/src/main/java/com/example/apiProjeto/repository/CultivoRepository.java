package com.example.apiProjeto.repository;

import com.example.apiProjeto.model.Cultivo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CultivoRepository extends JpaRepository<Cultivo, Long> {
    Cultivo findFirstByHabilitadaTrueOrderByIdDesc();
}
