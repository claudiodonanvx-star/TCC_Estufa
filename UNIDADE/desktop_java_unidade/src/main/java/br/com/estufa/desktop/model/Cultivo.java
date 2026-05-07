package br.com.estufa.desktop.model;

public class Cultivo {
    private Long id;
    private String nome;
    private String tipo;
    private float temperaturaMinima;
    private float temperaturaMaxima;
    private float umidadeMinima;
    private float umidadeMaxima;
    private float umidadeSoloMinima;
    private float umidadeSoloMaxima;
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

    public float getUmidadeSoloMinima() {
        return umidadeSoloMinima;
    }

    public void setUmidadeSoloMinima(float umidadeSoloMinima) {
        this.umidadeSoloMinima = umidadeSoloMinima;
    }

    public float getUmidadeSoloMaxima() {
        return umidadeSoloMaxima;
    }

    public void setUmidadeSoloMaxima(float umidadeSoloMaxima) {
        this.umidadeSoloMaxima = umidadeSoloMaxima;
    }

    public boolean isHabilitada() {
        return habilitada;
    }

    public void setHabilitada(boolean habilitada) {
        this.habilitada = habilitada;
    }
}
