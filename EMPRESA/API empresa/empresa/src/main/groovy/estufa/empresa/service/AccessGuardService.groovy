package estufa.empresa.service

import estufa.empresa.model.PerfilAcesso
import estufa.empresa.model.UsuarioEmpresa
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

@Service
class AccessGuardService {

    UsuarioEmpresa usuarioLogado(HttpServletRequest request) {
        def usuario = request.getAttribute("authUser") as UsuarioEmpresa
        if (usuario == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sessão inválida")
        }
        usuario
    }

    void exigirPerfis(HttpServletRequest request, PerfilAcesso... perfis) {
        def usuario = usuarioLogado(request)
        if (usuario.perfil == PerfilAcesso.ADMIN) {
            return
        }
        if (!perfis.contains(usuario.perfil)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sem permissão para esta operação")
        }
    }

    void exigirGerenteOuAdmin(HttpServletRequest request) {
        def usuario = usuarioLogado(request)
        if (usuario.perfil == PerfilAcesso.ADMIN || usuario.gerente || usuario.perfil == PerfilAcesso.GERENTE) {
            return
        }
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Apenas gerente ou admin podem cadastrar funcionários")
    }

    void exigirAdmin(HttpServletRequest request) {
        def usuario = usuarioLogado(request)
        if (usuario.perfil != PerfilAcesso.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Apenas admin pode executar esta operação")
        }
    }
}
