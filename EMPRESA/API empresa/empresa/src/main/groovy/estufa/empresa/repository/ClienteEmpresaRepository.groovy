package estufa.empresa.repository

import estufa.empresa.model.ClienteEmpresa
import org.springframework.data.jpa.repository.JpaRepository

interface ClienteEmpresaRepository extends JpaRepository<ClienteEmpresa, Long> {
    Long countByAtivoTrue()
}
