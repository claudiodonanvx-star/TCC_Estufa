package br.com.estufa.desktop.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Alerta {
    private Long id;
    private String tipo;        // TEMPERATURA, UMIDADE, SOLO
    private String severidade;  // CRITICO, ATENCAO
    private float valor;
    private float limiteMin;
    private float limiteMax;
    private String mensagem;
    private String geradoEm;    // ISO string da API

    public Alerta() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

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

    public String getGeradoEm() { return geradoEm; }
    public void setGeradoEm(String geradoEm) { this.geradoEm = geradoEm; }

    public boolean isCritico() { return "CRITICO".equalsIgnoreCase(severidade); }
}
