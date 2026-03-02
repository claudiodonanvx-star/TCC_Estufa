package estufa.empresa.repository

import estufa.empresa.model.Contrato
import estufa.empresa.model.ContratoStatus
import org.springframework.data.jpa.repository.JpaRepository

import java.time.LocalDate

interface ContratoRepository extends JpaRepository<Contrato, Long> {
    Long countByStatus(ContratoStatus status)
    List<Contrato> findTop6ByStatusAndFimEmAfterOrderByFimEmAsc(ContratoStatus status, LocalDate data)
}
