package com.example.apiProjeto.model;

import jakarta.persistence.*;

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
}
