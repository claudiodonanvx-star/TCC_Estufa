package com.example.apiProjeto.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Entity
@Table(name = "cultivos")
public class Cultivo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Nome do cultivo é obrigatório")
    private String nome;

    @NotBlank(message = "Tipo do cultivo é obrigatório")
    private String tipo;

    @NotNull(message = "A temperatura mínima é obrigatória")
    @DecimalMin(value = "0.0", inclusive = true, message = "A temperatura mínima deve ser maior ou igual a 0")
    private Float temperaturaMinima;

    @NotNull(message = "A temperatura máxima é obrigatória")
    @DecimalMin(value = "0.0", inclusive = true, message = "A temperatura máxima deve ser maior ou igual a 0")
    private Float temperaturaMaxima;

    @NotNull(message = "A umidade mínima é obrigatória")
    @DecimalMin(value = "0.0", inclusive = true, message = "A umidade mínima deve ser maior ou igual a 0")
    private Float umidadeMinima;

    @NotNull(message = "A umidade máxima é obrigatória")
    @DecimalMin(value = "0.0", inclusive = true, message = "A umidade máxima deve ser maior ou igual a 0")
    private Float umidadeMaxima;

    @NotNull(message = "A umidade do solo mínima é obrigatória")
    @DecimalMin(value = "0.0", inclusive = true, message = "A umidade do solo mínima deve ser maior ou igual a 0")
    private Float umidadeSoloMinima;

    @NotNull(message = "A umidade do solo máxima é obrigatória")
    @DecimalMin(value = "0.0", inclusive = true, message = "A umidade do solo máxima deve ser maior ou igual a 0")
    private Float umidadeSoloMaxima;

    private boolean habilitada;

    // Construtor vazio (necessário para desserialização JSON)
    public Cultivo() {
    }

    // Construtor com parâmetros (conveniente)
    public Cultivo(String nome, String tipo, Float temperaturaMinima, Float temperaturaMaxima,
                   Float umidadeMinima, Float umidadeMaxima, Float umidadeSoloMinima,
                   Float umidadeSoloMaxima) {
        this.nome = nome;
        this.tipo = tipo;
        this.temperaturaMinima = temperaturaMinima;
        this.temperaturaMaxima = temperaturaMaxima;
        this.umidadeMinima = umidadeMinima;
        this.umidadeMaxima = umidadeMaxima;
        this.umidadeSoloMinima = umidadeSoloMinima;
        this.umidadeSoloMaxima = umidadeSoloMaxima;
        this.habilitada = false;
    }

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

    public Float getTemperaturaMinima() {
        return temperaturaMinima;
    }

    public void setTemperaturaMinima(Float temperaturaMinima) {
        this.temperaturaMinima = temperaturaMinima;
    }

    public Float getTemperaturaMaxima() {
        return temperaturaMaxima;
    }

    public void setTemperaturaMaxima(Float temperaturaMaxima) {
        this.temperaturaMaxima = temperaturaMaxima;
    }

    public Float getUmidadeMinima() {
        return umidadeMinima;
    }

    public void setUmidadeMinima(Float umidadeMinima) {
        this.umidadeMinima = umidadeMinima;
    }

    public Float getUmidadeMaxima() {
        return umidadeMaxima;
    }

    public void setUmidadeMaxima(Float umidadeMaxima) {
        this.umidadeMaxima = umidadeMaxima;
    }

    public Float getUmidadeSoloMinima() {
        return umidadeSoloMinima;
    }

    public void setUmidadeSoloMinima(Float umidadeSoloMinima) {
        this.umidadeSoloMinima = umidadeSoloMinima;
    }

    public Float getUmidadeSoloMaxima() {
        return umidadeSoloMaxima;
    }

    public void setUmidadeSoloMaxima(Float umidadeSoloMaxima) {
        this.umidadeSoloMaxima = umidadeSoloMaxima;
    }

    public boolean isHabilitada() {
        return habilitada;
    }

    public void setHabilitada(boolean habilitada) {
        this.habilitada = habilitada;
    }
}
