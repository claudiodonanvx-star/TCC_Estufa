package estufa.empresa.service

import estufa.empresa.model.PerfilAcesso
import estufa.empresa.model.SessaoAcesso
import estufa.empresa.model.UsuarioEmpresa
import estufa.empresa.repository.SessaoAcessoRepository
import estufa.empresa.repository.UsuarioEmpresaRepository
import org.springframework.http.HttpStatus
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

import java.time.LocalDateTime
import java.util.UUID

@Service
class AuthService {

    private final UsuarioEmpresaRepository usuarioRepository
    private final SessaoAcessoRepository sessaoRepository
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder()

    AuthService(UsuarioEmpresaRepository usuarioRepository, SessaoAcessoRepository sessaoRepository) {
        this.usuarioRepository = usuarioRepository
        this.sessaoRepository = sessaoRepository
    }

    Map<String, Object> login(String login, String senha) {
        def usuario = usuarioRepository.findByLoginIgnoreCase(login ?: "").orElseThrow {
            new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Login ou senha inválidos")
        }

        if (!usuario.ativo || !senhaValida(senha, usuario.senhaHash)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Login ou senha inválidos")
        }

        def sessao = new SessaoAcesso(
                usuario: usuario,
                token: UUID.randomUUID().toString().replace("-", ""),
                expiraEm: LocalDateTime.now().plusHours(12),
                ativo: true
        )
        sessaoRepository.save(sessao)

        [
                token      : sessao.token,
                nome       : usuario.nome,
                login      : usuario.login,
                perfil     : usuario.perfil.name(),
                gerente    : usuario.gerente,
                permissoes : permissoes(usuario)
        ]
    }

    void logout(String token) {
        if (!token) {
            return
        }
        def sessao = sessaoRepository.findByTokenAndAtivoTrue(token)
        if (sessao.present) {
            def s = sessao.get()
            s.ativo = false
            sessaoRepository.save(s)
        }
    }

    UsuarioEmpresa autenticarToken(String token) {
        def sessao = sessaoRepository.findByTokenAndAtivoTrueAndExpiraEmAfter(token ?: "", LocalDateTime.now()).orElse(null)
        if (sessao == null || !sessao.usuario.ativo) {
            return null
        }
        sessao.usuario
    }

    Map<String, Object> me(UsuarioEmpresa usuario) {
        [
                id        : usuario.id,
                nome      : usuario.nome,
                login     : usuario.login,
                email     : usuario.email,
                perfil    : usuario.perfil.name(),
                gerente   : usuario.gerente,
                permissoes: permissoes(usuario)
        ]
    }

    List<String> permissoes(UsuarioEmpresa usuario) {
        if (usuario.perfil == PerfilAcesso.ADMIN) {
            return ["DASHBOARD", "COMERCIAL", "CONTRATOS", "UNIDADES", "ATIVIDADES", "USUARIOS", "USUARIOS_CADASTRAR"]
        }
        if (usuario.gerente || usuario.perfil == PerfilAcesso.GERENTE) {
            return ["DASHBOARD", "COMERCIAL", "CONTRATOS", "UNIDADES", "ATIVIDADES", "USUARIOS", "USUARIOS_CADASTRAR"]
        }
        if (usuario.perfil == PerfilAcesso.ANALISTA) {
            return ["DASHBOARD", "COMERCIAL", "CONTRATOS", "UNIDADES", "ATIVIDADES"]
        }
        ["DASHBOARD", "ATIVIDADES"]
    }

    String hashSenha(String senha) {
        encoder.encode(senha)
    }

    private boolean senhaValida(String senhaInformada, String senhaSalva) {
        if (!senhaSalva) {
            return false
        }

        String senha = senhaInformada ?: ""
        boolean pareceBcrypt = senhaSalva.startsWith('$2a$') || senhaSalva.startsWith('$2b$') || senhaSalva.startsWith('$2y$')

        if (!pareceBcrypt) {
            return senha == senhaSalva
        }

        try {
            return encoder.matches(senha, senhaSalva)
        } catch (Exception ignored) {
            return senha == senhaSalva
        }
    }
}
