package estufa.empresa.repository

import estufa.empresa.model.UsuarioEmpresa
import org.springframework.data.jpa.repository.JpaRepository

import java.util.Optional

interface UsuarioEmpresaRepository extends JpaRepository<UsuarioEmpresa, Long> {
    Optional<UsuarioEmpresa> findByLoginIgnoreCase(String login)
    Optional<UsuarioEmpresa> findByEmailIgnoreCase(String email)
}
