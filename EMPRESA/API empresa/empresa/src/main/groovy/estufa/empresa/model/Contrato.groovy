package estufa.empresa.model

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
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
@Table(name = "emp_contratos")
class Contrato {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cliente_id", nullable = false)
    ClienteEmpresa cliente

    @Enumerated(EnumType.STRING)
    @Column(name = "plano", nullable = false, length = 20)
    ContratoPlano plano

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    ContratoStatus status = ContratoStatus.TESTE

    @Column(name = "valor_mensal", nullable = false)
    BigDecimal valorMensal

    @Column(name = "inicio_em", nullable = false)
    LocalDate inicioEm

    @Column(name = "fim_em")
    LocalDate fimEm

    @Column(name = "renovacao_automatica", nullable = false)
    Boolean renovacaoAutomatica = false

    @Column(name = "criado_em", nullable = false)
    LocalDateTime criadoEm

    @PrePersist
    void prePersist() {
        if (criadoEm == null) {
            criadoEm = LocalDateTime.now()
        }
    }
}
