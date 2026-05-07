package com.example.apiProjeto.repository;

import com.example.apiProjeto.model.SensorData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

public interface SensorDataRepository extends JpaRepository<SensorData, Long> {

    @Query("SELECT s FROM SensorData s WHERE s.coletadoEm >= :inicio AND s.coletadoEm <= :fim ORDER BY s.coletadoEm")
    List<SensorData> findByPeriodo(@Param("inicio") LocalDateTime inicio, @Param("fim") LocalDateTime fim);

    @Modifying
    @Transactional
    @Query("DELETE FROM SensorData s WHERE s.coletadoEm IS NOT NULL AND s.coletadoEm < :corte")
    int deleteAnteriorA(@Param("corte") LocalDateTime corte);
}
