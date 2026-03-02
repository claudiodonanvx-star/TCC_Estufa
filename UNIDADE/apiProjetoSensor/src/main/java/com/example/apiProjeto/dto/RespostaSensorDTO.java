package com.example.apiProjeto.dto;

public class RespostaSensorDTO {
    private String significado;
    private int r;
    private int g;
    private int b;

    public RespostaSensorDTO(String significado, int r, int g, int b) {
        this.significado = significado;
        this.r = r;
        this.g = g;
        this.b = b;
    }

    public String getSignificado() { return significado; }
    public int getR() { return r; }
    public int getG() { return g; }
    public int getB() { return b; }
}
