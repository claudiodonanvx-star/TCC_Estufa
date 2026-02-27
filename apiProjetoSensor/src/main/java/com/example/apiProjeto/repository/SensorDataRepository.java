package com.example.apiProjeto.repository;

import com.example.apiProjeto.model.SensorData;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SensorDataRepository extends JpaRepository<SensorData, Long> {
}
