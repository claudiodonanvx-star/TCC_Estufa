package estufa.empresa.controller

import estufa.empresa.model.Contrato
import estufa.empresa.model.ContratoUnidade
import estufa.empresa.model.PerfilAcesso
import estufa.empresa.model.ContratoStatus
import estufa.empresa.repository.ClienteEmpresaRepository
import estufa.empresa.repository.ContratoRepository
import estufa.empresa.repository.ContratoUnidadeRepository
import estufa.empresa.repository.UnidadeOperacionalRepository
import estufa.empresa.service.AccessGuardService
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException

@RestController
@RequestMapping("/api/internal/contratos")
class ContratoController {

    private final ContratoRepository contratoRepository
    private final ClienteEmpresaRepository clienteRepository
    private final UnidadeOperacionalRepository unidadeRepository
    private final ContratoUnidadeRepository contratoUnidadeRepository
    private final AccessGuardService accessGuard

    ContratoController(
            ContratoRepository contratoRepository,
            ClienteEmpresaRepository clienteRepository,
            UnidadeOperacionalRepository unidadeRepository,
            ContratoUnidadeRepository contratoUnidadeRepository,
            AccessGuardService accessGuard
    ) {
        this.contratoRepository = contratoRepository
        this.clienteRepository = clienteRepository
        this.unidadeRepository = unidadeRepository
        this.contratoUnidadeRepository = contratoUnidadeRepository
        this.accessGuard = accessGuard
    }

    @GetMapping
    List<Map<String, Object>> listar(HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        contratoRepository.findAll().sort { a, b -> b.id <=> a.id }.collect { contrato ->
            def vinculos = contratoUnidadeRepository.findByContratoIdAndAtivoTrue(contrato.id)
            [
                    id                : contrato.id,
                    clienteId         : contrato.cliente.id,
                    cliente           : contrato.cliente.nomeFantasia ?: contrato.cliente.razaoSocial,
                    plano             : contrato.plano,
                    status            : contrato.status,
                    valorMensal       : contrato.valorMensal,
                    inicioEm          : contrato.inicioEm,
                    fimEm             : contrato.fimEm,
                    renovacaoAutomatica: contrato.renovacaoAutomatica,
                    qtdUnidades       : vinculos.size(),
                    unidades          : vinculos.collect { it.unidade.nomeUnidade }
            ]
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    Contrato criar(@RequestBody Map<String, Object> payload, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)
        Long clienteId = (payload.clienteId as Number)?.longValue()
        def cliente = clienteRepository.findById(clienteId).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Cliente não encontrado")
        }

        Contrato contrato = new Contrato(
                cliente: cliente,
                plano: payload.plano,
                status: payload.status ?: ContratoStatus.TESTE,
                valorMensal: payload.valorMensal,
                inicioEm: payload.inicioEm,
                fimEm: payload.fimEm,
                renovacaoAutomatica: payload.renovacaoAutomatica ?: false
        )
        contratoRepository.save(contrato)
    }

    @PatchMapping("/{id}/status/{status}")
    Contrato atualizarStatus(@PathVariable Long id, @PathVariable ContratoStatus status, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)
        def contrato = contratoRepository.findById(id).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Contrato não encontrado")
        }
        contrato.status = status
        contratoRepository.save(contrato)
    }

    @PostMapping("/{id}/unidades/{unidadeId}")
    @ResponseStatus(HttpStatus.CREATED)
    Map<String, Object> vincularUnidade(@PathVariable Long id, @PathVariable Long unidadeId, @RequestBody(required = false) Map<String, Object> payload, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)

        def contrato = contratoRepository.findById(id).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Contrato não encontrado")
        }
        def unidade = unidadeRepository.findById(unidadeId).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Unidade não encontrada")
        }

        if (contratoUnidadeRepository.existsByContratoIdAndUnidadeIdAndAtivoTrue(id, unidadeId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Unidade já vinculada a este contrato")
        }

        def vinculo = new ContratoUnidade(
                contrato: contrato,
                unidade: unidade,
                inicioVinculo: (payload?.inicioVinculo ?: java.time.LocalDate.now()) as java.time.LocalDate,
                fimVinculo: payload?.fimVinculo as java.time.LocalDate,
                ativo: payload?.ativo == null ? true : payload.ativo
        )
        contratoUnidadeRepository.save(vinculo)

        [status: "ok", mensagem: "Unidade vinculada ao contrato"]
    }
}
