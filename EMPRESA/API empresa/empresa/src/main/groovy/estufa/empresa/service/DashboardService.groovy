package estufa.empresa.service

import estufa.empresa.model.ContratoStatus
import estufa.empresa.model.LeadStatus
import estufa.empresa.repository.AtividadeImplantacaoRepository
import estufa.empresa.repository.ClienteEmpresaRepository
import estufa.empresa.repository.ContratoRepository
import estufa.empresa.repository.LeadRepository
import estufa.empresa.repository.UnidadeOperacionalRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

import java.time.LocalDate

@Service
class DashboardService {

    private final LeadRepository leadRepository
    private final ClienteEmpresaRepository clienteRepository
    private final ContratoRepository contratoRepository
    private final UnidadeOperacionalRepository unidadeRepository
    private final AtividadeImplantacaoRepository atividadeRepository

    DashboardService(
            LeadRepository leadRepository,
            ClienteEmpresaRepository clienteRepository,
            ContratoRepository contratoRepository,
            UnidadeOperacionalRepository unidadeRepository,
            AtividadeImplantacaoRepository atividadeRepository
    ) {
        this.leadRepository = leadRepository
        this.clienteRepository = clienteRepository
        this.contratoRepository = contratoRepository
        this.unidadeRepository = unidadeRepository
        this.atividadeRepository = atividadeRepository
    }

        @Transactional(readOnly = true)
        Map<String, Object> resumoGeral() {
        LocalDate hoje = LocalDate.now()
        LocalDate horizonte = hoje.plusDays(30)

        def leadsAbertos = leadRepository.countByStatusIn([LeadStatus.NOVO, LeadStatus.QUALIFICADO, LeadStatus.PROPOSTA])
        def clientesAtivos = clienteRepository.countByAtivoTrue()
        def contratosAtivos = contratoRepository.countByStatus(ContratoStatus.ATIVO)
        def unidadesAtivas = unidadeRepository.countByAtivaTrue()
        def atividadesPendentes = atividadeRepository.countByConcluidaFalse()

        def renovacoes = contratoRepository.findTop6ByStatusAndFimEmAfterOrderByFimEmAsc(ContratoStatus.ATIVO, hoje)
                .collect { contrato ->
                    [
                            id          : contrato.id,
                            cliente     : contrato.cliente?.nomeFantasia ?: contrato.cliente?.razaoSocial,
                            plano       : contrato.plano?.name(),
                            fimEm       : contrato.fimEm,
                            valorMensal : contrato.valorMensal
                    ]
                }

        def atividadesCriticas = atividadeRepository.findTop8ByConcluidaFalseOrderByPrazoEmAsc()
                .collect { atividade ->
                    [
                            id         : atividade.id,
                            unidade    : atividade.unidade?.nomeUnidade,
                            titulo     : atividade.titulo,
                            prioridade : atividade.prioridade?.name(),
                            prazoEm    : atividade.prazoEm,
                            responsavel: atividade.responsavel
                    ]
                }

        [
                totais             : [
                        leadsAbertos       : leadsAbertos,
                        clientesAtivos     : clientesAtivos,
                        contratosAtivos    : contratosAtivos,
                        unidadesAtivas     : unidadesAtivas,
                        atividadesPendentes: atividadesPendentes,
                        followUp30Dias     : leadRepository.countByProximoContatoEmBetween(hoje, horizonte)
                ],
                pipeline           : [
                        novos      : leadRepository.countByStatus(LeadStatus.NOVO),
                        qualificados: leadRepository.countByStatus(LeadStatus.QUALIFICADO),
                        proposta   : leadRepository.countByStatus(LeadStatus.PROPOSTA),
                        fechado    : leadRepository.countByStatus(LeadStatus.FECHADO)
                ],
                renovacoesProximas : renovacoes,
                atividadesPrioridade: atividadesCriticas
        ]
    }
}
