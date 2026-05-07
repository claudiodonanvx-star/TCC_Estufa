package com.example.apiProjeto.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "relatorio_diario", uniqueConstraints = @UniqueConstraint(columnNames = "data_ref"))
public class RelatorioDiario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "data_ref", nullable = false, unique = true)
    private LocalDate dataRef;

    private double tempMedia;
    private double tempMinima;
    private double tempMaxima;

    private double umidadeMedia;
    private double umidadeMinima;
    private double umidadeMaxima;

    private double soloMedia;
    private double soloMinima;
    private double soloMaxima;

    private int totalLeituras;

    @Column(name = "atualizado_em", columnDefinition = "DATETIME DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime atualizadoEm;

    @PrePersist
    @PreUpdate
    public void preUpdate() {
        atualizadoEm = LocalDateTime.now();
    }

    public RelatorioDiario() {}

    public Long getId() { return id; }

    public LocalDate getDataRef() { return dataRef; }
    public void setDataRef(LocalDate dataRef) { this.dataRef = dataRef; }

    public double getTempMedia() { return tempMedia; }
    public void setTempMedia(double tempMedia) { this.tempMedia = tempMedia; }

    public double getTempMinima() { return tempMinima; }
    public void setTempMinima(double tempMinima) { this.tempMinima = tempMinima; }

    public double getTempMaxima() { return tempMaxima; }
    public void setTempMaxima(double tempMaxima) { this.tempMaxima = tempMaxima; }

    public double getUmidadeMedia() { return umidadeMedia; }
    public void setUmidadeMedia(double umidadeMedia) { this.umidadeMedia = umidadeMedia; }

    public double getUmidadeMinima() { return umidadeMinima; }
    public void setUmidadeMinima(double umidadeMinima) { this.umidadeMinima = umidadeMinima; }

    public double getUmidadeMaxima() { return umidadeMaxima; }
    public void setUmidadeMaxima(double umidadeMaxima) { this.umidadeMaxima = umidadeMaxima; }

    public double getSoloMedia() { return soloMedia; }
    public void setSoloMedia(double soloMedia) { this.soloMedia = soloMedia; }

    public double getSoloMinima() { return soloMinima; }
    public void setSoloMinima(double soloMinima) { this.soloMinima = soloMinima; }

    public double getSoloMaxima() { return soloMaxima; }
    public void setSoloMaxima(double soloMaxima) { this.soloMaxima = soloMaxima; }

    public int getTotalLeituras() { return totalLeituras; }
    public void setTotalLeituras(int totalLeituras) { this.totalLeituras = totalLeituras; }

    public LocalDateTime getAtualizadoEm() { return atualizadoEm; }
}
