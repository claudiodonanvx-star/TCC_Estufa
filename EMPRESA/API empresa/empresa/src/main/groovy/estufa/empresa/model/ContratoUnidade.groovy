package estufa.empresa.model

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.PrePersist
import jakarta.persistence.Table

import java.time.LocalDate
import java.time.LocalDateTime

@Entity
@Table(name = "emp_contrato_unidades")
class ContratoUnidade {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contrato_id", nullable = false)
    Contrato contrato

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unidade_id", nullable = false)
    UnidadeOperacional unidade

    @Column(name = "inicio_vinculo", nullable = false)
    LocalDate inicioVinculo

    @Column(name = "fim_vinculo")
    LocalDate fimVinculo

    @Column(name = "ativo", nullable = false)
    Boolean ativo = true

    @Column(name = "criado_em", nullable = false)
    LocalDateTime criadoEm

    @PrePersist
    void prePersist() {
        if (criadoEm == null) {
            criadoEm = LocalDateTime.now()
        }
    }
}
