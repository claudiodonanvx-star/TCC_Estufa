package estufa.empresa.repository

import estufa.empresa.model.SessaoAcesso
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository

import java.time.LocalDateTime
import java.util.Optional

interface SessaoAcessoRepository extends JpaRepository<SessaoAcesso, Long> {
    @EntityGraph(attributePaths = ["usuario"])
    Optional<SessaoAcesso> findByTokenAndAtivoTrueAndExpiraEmAfter(String token, LocalDateTime dataHora)
    Optional<SessaoAcesso> findByTokenAndAtivoTrue(String token)
}
