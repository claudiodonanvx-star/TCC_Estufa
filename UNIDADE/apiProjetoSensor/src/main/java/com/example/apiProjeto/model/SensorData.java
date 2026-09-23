package com.example.apiProjeto.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import java.time.LocalDateTime;

@Entity
@Table(name = "sensor_data")
public class SensorData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @DecimalMin(value = "-50.0", message = "A temperatura deve ser maior ou igual a -50 °C")
    @DecimalMax(value = "80.0", message = "A temperatura deve ser menor ou igual a 80 °C")
    private float temperatura;

    @DecimalMin(value = "0.0", message = "A umidade deve ser maior ou igual a 0%")
    @DecimalMax(value = "100.0", message = "A umidade deve ser menor ou igual a 100%")
    private float umidade;

    @DecimalMin(value = "0.0", message = "A umidade do solo deve ser maior ou igual a 0%")
    @DecimalMax(value = "100.0", message = "A umidade do solo deve ser menor ou igual a 100%")
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
