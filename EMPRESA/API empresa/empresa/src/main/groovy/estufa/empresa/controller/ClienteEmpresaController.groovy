package estufa.empresa.controller

import estufa.empresa.model.ClienteEmpresa
import estufa.empresa.model.PerfilAcesso
import estufa.empresa.repository.ClienteEmpresaRepository
import estufa.empresa.service.AccessGuardService
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/internal/clientes")
class ClienteEmpresaController {

    private final ClienteEmpresaRepository repository
    private final AccessGuardService accessGuard

    ClienteEmpresaController(ClienteEmpresaRepository repository, AccessGuardService accessGuard) {
        this.repository = repository
        this.accessGuard = accessGuard
    }

    @GetMapping
    List<ClienteEmpresa> listar(HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA, PerfilAcesso.OPERADOR)
        repository.findAll().sort { a, b -> b.id <=> a.id }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    ClienteEmpresa criar(@RequestBody ClienteEmpresa cliente, HttpServletRequest request) {
        accessGuard.exigirPerfis(request, PerfilAcesso.GERENTE, PerfilAcesso.ANALISTA)
        repository.save(cliente)
    }
}
