package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.Cliente;
import com.example.apiProjeto.model.ClientePendente;
import com.example.apiProjeto.model.StatusCadastro;
import com.example.apiProjeto.model.Usuario;
import com.example.apiProjeto.repository.ClientePendenteRepository;
import com.example.apiProjeto.repository.ClienteRepository;
import com.example.apiProjeto.repository.UsuarioRepository;
import com.example.apiProjeto.service.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Map;
import java.util.Optional;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    @Autowired
    private UsuarioRepository usuarioRepository;
    @Autowired
    private ClienteRepository clienteRepository;
    @Autowired
    private ClientePendenteRepository clientePendenteRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final JwtService jwtService;

    public UsuarioController(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @PostMapping("/cadastro")
    public ResponseEntity<?> cadastrar(@Valid @RequestBody Usuario usuario) {
        if (usuarioRepository.findByLogin(usuario.getLogin()).isPresent()) {
            return ResponseEntity.badRequest().body("Usuário já existe");
        }
        usuario.setSenha(passwordEncoder.encode(usuario.getSenha()));
        return ResponseEntity.ok(usuarioRepository.save(usuario));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody Usuario usuario) {

        Optional<Usuario> u = usuarioRepository.findByLogin(usuario.getLogin());

        if (u.isPresent() && senhaValida(usuario.getSenha(), u.get())) {
            if (!u.get().getSenha().startsWith("$2a$") && !u.get().getSenha().startsWith("$2b$")) {
                u.get().setSenha(passwordEncoder.encode(usuario.getSenha()));
                usuarioRepository.save(u.get());
            }
                Optional<Cliente> clienteOpt = clienteRepository.findByUsuario(usuario.getLogin())
                    .or(() -> clienteRepository.findByCpf(usuario.getLogin()));
            if (clienteOpt.isPresent()) {
                Cliente cliente = clienteOpt.get();
                if (!cliente.isAtivo()) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                            Map.of("mensagem", "Usuário inativo. Entre em contato com o administrador.")
                    );
                }

                long pendencias = 0;
                if (cliente.isAdministrador()) {
                    pendencias = clientePendenteRepository.countByStatusCadastro(StatusCadastro.PENDENTE);
                }

                System.out.println("Login bem-sucedido");
                return ResponseEntity.ok(
                        Map.of(
                                "mensagem", "Login bem-sucedido",
                                "token", jwtService.gerarToken(usuario.getLogin()),
                                "cpf", cliente.getCpf() == null ? usuario.getLogin() : cliente.getCpf(),
                                "administrador", cliente.isAdministrador(),
                                "pendenciasAprovacao", pendencias
                        )
                );
            }

            return ResponseEntity.ok(
                        Map.of(
                            "mensagem", "Login bem-sucedido",
                            "token", jwtService.gerarToken(usuario.getLogin()),
                            "cpf", usuario.getLogin(),
                            "administrador", false,
                            "pendenciasAprovacao", 0
                    )
            );
        }

        Optional<ClientePendente> pendenteOpt = clientePendenteRepository.findTopByUsuarioOrderByIdDesc(usuario.getLogin())
            .or(() -> clientePendenteRepository.findTopByCpfOrderByIdDesc(usuario.getLogin()));
        if (pendenteOpt.isPresent()) {
            ClientePendente pendente = pendenteOpt.get();
            if (pendente.getStatusCadastro() == StatusCadastro.PENDENTE) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                        Map.of("mensagem", "Registro encontrado e ainda não liberado")
                );
            }
            if (pendente.getStatusCadastro() == StatusCadastro.RECUSADO) {
                String motivo = (pendente.getMotivoRecusa() == null || pendente.getMotivoRecusa().isBlank())
                        ? "Registro recusado pelo administrador."
                        : pendente.getMotivoRecusa();
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
                        Map.of("mensagem", motivo)
                );
            }
        }

        System.out.println("Login falhou");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("mensagem", "Login inválido"));
    }

    private boolean senhaValida(String senhaInformada, Usuario usuario) {
        String senhaArmazenada = usuario.getSenha();
        return senhaArmazenada != null
                && (senhaArmazenada.startsWith("$2a$") || senhaArmazenada.startsWith("$2b$")
                    ? passwordEncoder.matches(senhaInformada, senhaArmazenada)
                    : senhaArmazenada.equals(senhaInformada));
    }
}
