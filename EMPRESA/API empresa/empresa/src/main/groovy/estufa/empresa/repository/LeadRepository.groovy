package estufa.empresa.repository

import estufa.empresa.model.Lead
import estufa.empresa.model.LeadStatus
import org.springframework.data.jpa.repository.JpaRepository

import java.time.LocalDate

interface LeadRepository extends JpaRepository<Lead, Long> {
    Long countByStatusIn(Collection<LeadStatus> status)
    Long countByStatus(LeadStatus status)
    Long countByProximoContatoEmBetween(LocalDate inicio, LocalDate fim)
}
