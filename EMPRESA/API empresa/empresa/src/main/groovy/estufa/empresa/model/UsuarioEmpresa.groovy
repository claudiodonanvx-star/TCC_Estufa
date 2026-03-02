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
@Table(name = "emp_usuarios")
class UsuarioEmpresa {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @Column(name = "nome", nullable = false, length = 120)
    String nome

    @Column(name = "email", nullable = false, unique = true, length = 140)
    String email

    @Column(name = "login", nullable = false, unique = true, length = 60)
    String login

    @Column(name = "senha_hash", nullable = false, length = 120)
    String senhaHash

    @Enumerated(EnumType.STRING)
    @Column(name = "perfil", nullable = false, length = 20)
    PerfilAcesso perfil

    @Column(name = "gerente", nullable = false)
    Boolean gerente = false

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
