package estufa.empresa.repository

import estufa.empresa.model.UnidadeOperacional
import org.springframework.data.jpa.repository.JpaRepository

interface UnidadeOperacionalRepository extends JpaRepository<UnidadeOperacional, Long> {
    Long countByAtivaTrue()
}
