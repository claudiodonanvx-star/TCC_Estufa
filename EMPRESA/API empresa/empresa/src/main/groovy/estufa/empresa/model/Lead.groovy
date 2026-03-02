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

import java.time.LocalDate
import java.time.LocalDateTime

@Entity
@Table(name = "emp_leads")
class Lead {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @Column(name = "nome_contato", nullable = false, length = 120)
    String nomeContato

    @Column(name = "empresa", nullable = false, length = 140)
    String empresa

    @Column(name = "email", length = 140)
    String email

    @Column(name = "telefone", length = 40)
    String telefone

    @Column(name = "origem", length = 80)
    String origem

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    LeadStatus status = LeadStatus.NOVO

    @Column(name = "valor_estimado")
    BigDecimal valorEstimado

    @Column(name = "proximo_contato_em")
    LocalDate proximoContatoEm

    @Column(name = "observacao", length = 400)
    String observacao

    @Column(name = "criado_em", nullable = false)
    LocalDateTime criadoEm

    @PrePersist
    void prePersist() {
        if (criadoEm == null) {
            criadoEm = LocalDateTime.now()
        }
    }
}
