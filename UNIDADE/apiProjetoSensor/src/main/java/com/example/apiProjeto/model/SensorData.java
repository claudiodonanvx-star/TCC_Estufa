package com.example.apiProjeto.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sensor_data")
public class SensorData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private float temperatura;
    private float umidade;
    private Float umidadeSolo;
    private String significado;

    @Column(name = "coletado_em", columnDefinition = "DATETIME DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime coletadoEm;

    @PrePersist
    public void prePersist() {
        if (coletadoEm == null) {
            coletadoEm = LocalDateTime.now();
        }
    }

    public SensorData() {}

    public SensorData(float temperatura, float umidade) {
        this.temperatura = temperatura;
        this.umidade = umidade;
    }

    public Long getId() { return id; }

    public float getTemperatura() { return temperatura; }
    public void setTemperatura(float temperatura) { this.temperatura = temperatura; }

    public float getUmidade() { return umidade; }
    public void setUmidade(float umidade) { this.umidade = umidade; }

    public Float getUmidadeSolo() { return umidadeSolo; }
    public void setUmidadeSolo(Float umidadeSolo) { this.umidadeSolo = umidadeSolo; }

    public String getSignificado() {
        return significado;
    }
    public void setSignificado(String significado) {
        this.significado = significado;
    }

    public LocalDateTime getColetadoEm() {
        return coletadoEm;
    }
    public void setColetadoEm(LocalDateTime coletadoEm) {
        this.coletadoEm = coletadoEm;
    }
}
