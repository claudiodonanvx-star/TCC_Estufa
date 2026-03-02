package estufa.empresa.model

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.PrePersist
import jakarta.persistence.Table

import java.time.LocalDateTime

@Entity
@Table(name = "emp_clientes")
class ClienteEmpresa {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id

    @Column(name = "razao_social", nullable = false, length = 150)
    String razaoSocial

    @Column(name = "nome_fantasia", length = 150)
    String nomeFantasia

    @Column(name = "cnpj", nullable = false, unique = true, length = 18)
    String cnpj

    @Column(name = "segmento", length = 80)
    String segmento

    @Column(name = "cidade", length = 80)
    String cidade

    @Column(name = "estado", length = 2)
    String estado

    @Column(name = "contato_nome", length = 120)
    String contatoNome

    @Column(name = "contato_email", length = 140)
    String contatoEmail

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
