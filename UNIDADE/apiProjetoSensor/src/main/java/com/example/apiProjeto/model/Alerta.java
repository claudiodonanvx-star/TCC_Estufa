package com.example.apiProjeto.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "alertas")
public class Alerta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 20)
    private String tipo; // TEMPERATURA, UMIDADE, SOLO

    @Column(nullable = false, length = 10)
    private String severidade; // CRITICO, ATENCAO

    private float valor;
    private float limiteMin;
    private float limiteMax;

    @Column(length = 200)
    private String mensagem;

    @Column(name = "gerado_em")
    private LocalDateTime geradoEm;

    @PrePersist
    public void prePersist() {
        if (geradoEm == null) {
            geradoEm = LocalDateTime.now();
        }
    }

    public Alerta() {}

    public Alerta(String tipo, String severidade, float valor, float limiteMin, float limiteMax, String mensagem) {
        this.tipo = tipo;
        this.severidade = severidade;
        this.valor = valor;
        this.limiteMin = limiteMin;
        this.limiteMax = limiteMax;
        this.mensagem = mensagem;
    }

    public Long getId() { return id; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getSeveridade() { return severidade; }
    public void setSeveridade(String severidade) { this.severidade = severidade; }
    public float getValor() { return valor; }
    public void setValor(float valor) { this.valor = valor; }
    public float getLimiteMin() { return limiteMin; }
    public void setLimiteMin(float limiteMin) { this.limiteMin = limiteMin; }
    public float getLimiteMax() { return limiteMax; }
    public void setLimiteMax(float limiteMax) { this.limiteMax = limiteMax; }
    public String getMensagem() { return mensagem; }
    public void setMensagem(String mensagem) { this.mensagem = mensagem; }
    public LocalDateTime getGeradoEm() { return geradoEm; }
    public void setGeradoEm(LocalDateTime geradoEm) { this.geradoEm = geradoEm; }
}
