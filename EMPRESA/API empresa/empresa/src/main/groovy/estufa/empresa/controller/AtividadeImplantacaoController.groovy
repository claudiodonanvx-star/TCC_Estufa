package estufa.empresa.controller

import estufa.empresa.model.AtividadeImplantacao
import estufa.empresa.model.PerfilAcesso
import estufa.empresa.repository.AtividadeImplantacaoRepository
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
@RequestMapping("/api/internal/atividades")
class AtividadeImplantacaoController {

    private final AtividadeImplantacaoRepository atividadeRepository
    private final UnidadeOperacionalRepository unidadeRepository
    private final AccessGuardService accessGuard

    AtividadeImplantacaoController(AtividadeImplantacaoRepository atividadeRepository, UnidadeOperacionalRepository unidadeRepository, AccessGuardService accessGuard) {
        this.atividadeRepository = atividadeRepository
        this.unidadeRepository = unidadeRepository
        this.accessGuard = accessGuard
    }

    @GetMapping
    List<Map<String, Object>> listar(HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        atividadeRepository.findAll().sort { a, b -> b.id <=> a.id }.collect { atividade ->
            [
                    id         : atividade.id,
                    unidadeId  : atividade.unidade.id,
                    unidade    : atividade.unidade.nomeUnidade,
                    titulo     : atividade.titulo,
                    descricao  : atividade.descricao,
                    prioridade : atividade.prioridade,
                    responsavel: atividade.responsavel,
                    prazoEm    : atividade.prazoEm,
                    concluida  : atividade.concluida
            ]
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    AtividadeImplantacao criar(@RequestBody Map<String, Object> payload, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        Long unidadeId = (payload.unidadeId as Number)?.longValue()
        def unidade = unidadeRepository.findById(unidadeId).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Unidade não encontrada")
        }

        AtividadeImplantacao atividade = new AtividadeImplantacao(
                unidade: unidade,
                titulo: payload.titulo,
                descricao: payload.descricao,
                prioridade: payload.prioridade,
                responsavel: payload.responsavel,
                prazoEm: payload.prazoEm,
                concluida: payload.concluida ?: false
        )
        atividadeRepository.save(atividade)
    }

    @PatchMapping("/{id}/concluir")
    AtividadeImplantacao concluir(@PathVariable Long id, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        def atividade = atividadeRepository.findById(id).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Atividade não encontrada")
        }
        atividade.concluida = true
        atividadeRepository.save(atividade)
    }
}
