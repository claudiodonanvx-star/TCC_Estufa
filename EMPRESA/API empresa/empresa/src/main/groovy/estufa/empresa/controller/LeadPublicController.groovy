package estufa.empresa.controller

import estufa.empresa.model.Lead
import estufa.empresa.model.LeadStatus
import estufa.empresa.repository.LeadRepository
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/public/leads")
class LeadPublicController {

    private final LeadRepository repository

    LeadPublicController(LeadRepository repository) {
        this.repository = repository
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    Map<String, Object> captarLead(@RequestBody Map<String, Object> payload) {
        def lead = new Lead(
                nomeContato: payload.nomeContato,
                empresa: payload.empresa,
                email: payload.email,
                telefone: payload.telefone,
                origem: "SITE_COMERCIAL",
                status: LeadStatus.NOVO,
                observacao: payload.observacao,
                valorEstimado: payload.valorEstimado
        )
        repository.save(lead)
        [status: "ok", mensagem: "Lead recebido com sucesso"]
    }
}
