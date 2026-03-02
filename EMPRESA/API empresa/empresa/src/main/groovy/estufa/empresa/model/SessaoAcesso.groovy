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

import java.time.LocalDateTime

@Entity
@Table(name = "emp_sessoes")
class SessaoAcesso {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    UsuarioEmpresa usuario

    @Column(name = "token", nullable = false, unique = true, length = 80)
    String token

    @Column(name = "expira_em", nullable = false)
    LocalDateTime expiraEm

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
