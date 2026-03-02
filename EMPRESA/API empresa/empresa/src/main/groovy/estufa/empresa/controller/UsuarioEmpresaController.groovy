package estufa.empresa.controller

import estufa.empresa.model.PerfilAcesso
import estufa.empresa.model.UsuarioEmpresa
import estufa.empresa.repository.UsuarioEmpresaRepository
import estufa.empresa.service.AccessGuardService
import estufa.empresa.service.AuthService
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
@RequestMapping("/api/internal/usuarios")
class UsuarioEmpresaController {

    private final UsuarioEmpresaRepository usuarioRepository
    private final AccessGuardService accessGuard
    private final AuthService authService

    UsuarioEmpresaController(UsuarioEmpresaRepository usuarioRepository, AccessGuardService accessGuard, AuthService authService) {
        this.usuarioRepository = usuarioRepository
        this.accessGuard = accessGuard
        this.authService = authService
    }

    @GetMapping
    List<Map<String, Object>> listar(HttpServletRequest request) {
        accessGuard.exigirGerenteOuAdmin(request)
        usuarioRepository.findAll().sort { a, b -> b.id <=> a.id }.collect { u ->
            [
                    id     : u.id,
                    nome   : u.nome,
                    login  : u.login,
                    email  : u.email,
                    perfil : u.perfil.name(),
                    gerente: u.gerente,
                    ativo  : u.ativo
            ]
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    Map<String, Object> criar(@RequestBody Map<String, Object> payload, HttpServletRequest request) {
        def solicitante = accessGuard.usuarioLogado(request)
        accessGuard.exigirGerenteOuAdmin(request)

        PerfilAcesso perfil = PerfilAcesso.valueOf((payload.perfil ?: "OPERADOR") as String)
        if (solicitante.perfil != PerfilAcesso.ADMIN && perfil == PerfilAcesso.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Gerente não pode criar usuário ADMIN")
        }

        def usuario = new UsuarioEmpresa(
                nome: payload.nome,
                email: payload.email,
                login: payload.login,
                senhaHash: authService.hashSenha(payload.senha as String),
                perfil: perfil,
                gerente: payload.gerente == null ? (perfil == PerfilAcesso.GERENTE) : payload.gerente,
                ativo: payload.ativo == null ? true : payload.ativo
        )

        if (usuarioRepository.findByLoginIgnoreCase(usuario.login).present) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Login já cadastrado")
        }

        usuarioRepository.save(usuario)
        [status: "ok", mensagem: "Funcionário cadastrado"]
    }

    @PatchMapping("/{id}/ativo/{ativo}")
    Map<String, Object> atualizarAtivo(@PathVariable Long id, @PathVariable Boolean ativo, HttpServletRequest request) {
        accessGuard.exigirGerenteOuAdmin(request)
        def usuario = usuarioRepository.findById(id).orElseThrow {
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário não encontrado")
        }
        usuario.ativo = ativo
        usuarioRepository.save(usuario)
        [status: "ok", mensagem: "Status atualizado"]
    }
}
