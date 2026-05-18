package br.com.estufa.desktop.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class SensorData {
    private Long id;
    private float temperatura;
    private float umidade;
    private Float umidadeSolo;
    private String significado;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public float getTemperatura() {
        return temperatura;
    }

    public void setTemperatura(float temperatura) {
        this.temperatura = temperatura;
    }

    public float getUmidade() {
        return umidade;
    }

    public void setUmidade(float umidade) {
        this.umidade = umidade;
    }

    public Float getUmidadeSolo() {
        return umidadeSolo;
    }

    public void setUmidadeSolo(Float umidadeSolo) {
        this.umidadeSolo = umidadeSolo;
    }

    public String getSignificado() {
        return significado;
    }

    public void setSignificado(String significado) {
        this.significado = significado;
    }

    public double umidadeSoloOuZero() {
        return umidadeSolo == null ? 0.0 : umidadeSolo;
    }
}
