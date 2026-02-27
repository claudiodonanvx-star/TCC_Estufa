package com.example.apiProjeto.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "cultivos")
public class Cultivo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nome;
    private String tipo;
    private float temperaturaMinima;
    private float temperaturaMaxima;
    private float umidadeMinima;
    private float umidadeMaxima;
    private boolean habilitada;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public float getTemperaturaMinima() {
        return temperaturaMinima;
    }

    public void setTemperaturaMinima(float temperaturaMinima) {
        this.temperaturaMinima = temperaturaMinima;
    }

    public float getTemperaturaMaxima() {
        return temperaturaMaxima;
    }

    public void setTemperaturaMaxima(float temperaturaMaxima) {
        this.temperaturaMaxima = temperaturaMaxima;
    }

    public float getUmidadeMinima() {
        return umidadeMinima;
    }

    public void setUmidadeMinima(float umidadeMinima) {
        this.umidadeMinima = umidadeMinima;
    }

    public float getUmidadeMaxima() {
        return umidadeMaxima;
    }

    public void setUmidadeMaxima(float umidadeMaxima) {
        this.umidadeMaxima = umidadeMaxima;
    }

    public boolean isHabilitada() {
        return habilitada;
    }

    public void setHabilitada(boolean habilitada) {
        this.habilitada = habilitada;
    }
}
