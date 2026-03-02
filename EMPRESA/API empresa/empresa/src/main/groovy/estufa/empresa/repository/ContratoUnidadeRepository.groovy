package estufa.empresa.repository

import estufa.empresa.model.ContratoUnidade
import org.springframework.data.jpa.repository.JpaRepository

interface ContratoUnidadeRepository extends JpaRepository<ContratoUnidade, Long> {
    List<ContratoUnidade> findByContratoIdAndAtivoTrue(Long contratoId)
    List<ContratoUnidade> findByUnidadeIdAndAtivoTrue(Long unidadeId)
    boolean existsByContratoIdAndUnidadeIdAndAtivoTrue(Long contratoId, Long unidadeId)
}
