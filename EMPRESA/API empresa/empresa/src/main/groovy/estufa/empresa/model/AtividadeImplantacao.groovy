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
@Table(name = "emp_atividades")
class AtividadeImplantacao {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unidade_id", nullable = false)
    UnidadeOperacional unidade

    @Column(name = "titulo", nullable = false, length = 140)
    String titulo

    @Column(name = "descricao", length = 400)
    String descricao

    @Enumerated(EnumType.STRING)
    @Column(name = "prioridade", nullable = false, length = 20)
    PrioridadeAtividade prioridade = PrioridadeAtividade.MEDIA

    @Column(name = "responsavel", length = 120)
    String responsavel

    @Column(name = "prazo_em")
    LocalDate prazoEm

    @Column(name = "concluida", nullable = false)
    Boolean concluida = false

    @Column(name = "criado_em", nullable = false)
    LocalDateTime criadoEm

    @PrePersist
    void prePersist() {
        if (criadoEm == null) {
            criadoEm = LocalDateTime.now()
        }
    }
}
