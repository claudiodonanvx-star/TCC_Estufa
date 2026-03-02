package estufa.empresa.repository

import estufa.empresa.model.AtividadeImplantacao
import org.springframework.data.jpa.repository.JpaRepository

interface AtividadeImplantacaoRepository extends JpaRepository<AtividadeImplantacao, Long> {
    Long countByConcluidaFalse()
    List<AtividadeImplantacao> findTop8ByConcluidaFalseOrderByPrazoEmAsc()
}
