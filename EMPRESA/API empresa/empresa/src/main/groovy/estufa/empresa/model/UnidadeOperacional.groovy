package estufa.empresa.model

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.PrePersist
import jakarta.persistence.Table

import java.time.LocalDateTime

@Entity
@Table(name = "emp_unidades")
class UnidadeOperacional {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @Column(name = "nome_unidade", nullable = false, length = 120)
    String nomeUnidade

    @Column(name = "cidade", length = 80)
    String cidade

    @Column(name = "estado", length = 2)
    String estado

    @Column(name = "quantidade_estufas", nullable = false)
    Integer quantidadeEstufas = 1

    @Column(name = "ativa", nullable = false)
    Boolean ativa = true

    @Enumerated(EnumType.STRING)
    @Column(name = "status_financeiro", nullable = false, length = 20)
    StatusFinanceiro statusFinanceiro = StatusFinanceiro.ATIVO

    @Column(name = "ultima_sincronizacao")
    LocalDateTime ultimaSincronizacao

    @Column(name = "criado_em", nullable = false)
    LocalDateTime criadoEm

    @PrePersist
    void prePersist() {
        if (criadoEm == null) {
            criadoEm = LocalDateTime.now()
        }
    }
}
