package estufa.empresa.controller

import estufa.empresa.model.Lead
import estufa.empresa.model.LeadStatus
import estufa.empresa.model.PerfilAcesso
import estufa.empresa.repository.LeadRepository
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
@RequestMapping("/api/internal/leads")
class LeadController {

    private final LeadRepository repository
    private final AccessGuardService accessGuard

    LeadController(LeadRepository repository, AccessGuardService accessGuard) {
        this.repository = repository
        this.accessGuard = accessGuard
    }

    @GetMapping
    List<Lead> listar(HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        repository.findAll().sort { a, b -> b.id <=> a.id }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    Lead criar(@RequestBody Lead lead, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)
        repository.save(lead)
    }

    @PatchMapping("/{id}/status/{status}")
    Lead atualizarStatus(@PathVariable Long id, @PathVariable LeadStatus status, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)
        def lead = repository.findById(id).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Lead não encontrado")
        }
        lead.status = status
        repository.save(lead)
    }
}
