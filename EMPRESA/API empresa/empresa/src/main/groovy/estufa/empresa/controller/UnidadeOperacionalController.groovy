package estufa.empresa.controller

import estufa.empresa.model.UnidadeOperacional
import estufa.empresa.model.PerfilAcesso
import estufa.empresa.model.StatusFinanceiro
import estufa.empresa.repository.ContratoUnidadeRepository
import estufa.empresa.repository.UnidadeOperacionalRepository
import estufa.empresa.service.AccessGuardService
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException

@RestController
@RequestMapping("/api/internal/unidades")
class UnidadeOperacionalController {

    private final UnidadeOperacionalRepository unidadeRepository
    private final ContratoUnidadeRepository contratoUnidadeRepository
    private final AccessGuardService accessGuard

    UnidadeOperacionalController(
            UnidadeOperacionalRepository unidadeRepository,
            ContratoUnidadeRepository contratoUnidadeRepository,
            AccessGuardService accessGuard
    ) {
        this.unidadeRepository = unidadeRepository
        this.contratoUnidadeRepository = contratoUnidadeRepository
        this.accessGuard = accessGuard
    }

    @GetMapping
    List<Map<String, Object>> listar(HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        unidadeRepository.findAll().sort { a, b -> b.id <=> a.id }.collect { unidade ->
            def vinculos = contratoUnidadeRepository.findByUnidadeIdAndAtivoTrue(unidade.id)
            [
                    id                : unidade.id,
                    nomeUnidade       : unidade.nomeUnidade,
                    cidade            : unidade.cidade,
                    estado            : unidade.estado,
                    quantidadeEstufas : unidade.quantidadeEstufas,
                    ativa             : unidade.ativa,
                    statusFinanceiro  : unidade.statusFinanceiro?.name(),
                    ultimaSincronizacao: unidade.ultimaSincronizacao,
                    contratos         : vinculos.collect { v ->
                        [
                                contratoId: v.contrato.id,
                                cliente   : v.contrato.cliente.nomeFantasia ?: v.contrato.cliente.razaoSocial,
                                plano     : v.contrato.plano.name(),
                                status    : v.contrato.status.name()
                        ]
                    }
            ]
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    UnidadeOperacional criar(@RequestBody Map<String, Object> payload, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)
        UnidadeOperacional unidade = new UnidadeOperacional(
                nomeUnidade: payload.nomeUnidade,
                cidade: payload.cidade,
                estado: payload.estado,
                quantidadeEstufas: payload.quantidadeEstufas ?: 1,
                ativa: payload.ativa == null ? true : payload.ativa,
                statusFinanceiro: (payload.ativa == null ? true : payload.ativa) ? StatusFinanceiro.ATIVO : StatusFinanceiro.CANCELADO,
                ultimaSincronizacao: payload.ultimaSincronizacao
        )
        unidadeRepository.save(unidade)
    }
}
