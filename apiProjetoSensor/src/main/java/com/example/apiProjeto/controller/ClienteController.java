package com.example.apiProjeto.controller;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.apiProjeto.model.Cliente;
import com.example.apiProjeto.model.ClientePendente;
import com.example.apiProjeto.model.StatusCadastro;
import com.example.apiProjeto.model.Usuario;
import com.example.apiProjeto.repository.ClientePendenteRepository;
import com.example.apiProjeto.repository.ClienteRepository;
import com.example.apiProjeto.repository.UsuarioRepository;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/clientes")
public class ClienteController {

    @Autowired
    private ClienteRepository clienteRepository;
    @Autowired
    private ClientePendenteRepository clientePendenteRepository;
    @Autowired
    private UsuarioRepository usuarioRepository;

    @PostMapping("/cadastro")
    public ResponseEntity<?> cadastrarCliente(@RequestBody Cliente cliente) {
        if (clienteRepository.existsByCpf(cliente.getCpf())) {
            return ResponseEntity.badRequest().body("❌ Cliente com esse CPF já existe.");
        }
        if (clientePendenteRepository.existsByCpfAndStatusCadastro(cliente.getCpf(), StatusCadastro.PENDENTE)) {
            return ResponseEntity.badRequest().body("❌ Já existe um registro pendente para esse CPF.");
        }

        ClientePendente pendente = new ClientePendente();
        pendente.setNome(cliente.getNome());
        pendente.setTelefone(cliente.getTelefone());
        pendente.setEmail(cliente.getEmail());
        pendente.setCpf(cliente.getCpf());
        pendente.setSexo(cliente.getSexo());
        pendente.setSenha(cliente.getSenha());
        pendente.setCep(cliente.getCep());
        pendente.setCidade(cliente.getCidade());
        pendente.setBairro(cliente.getBairro());
        pendente.setNumero(cliente.getNumero());
        pendente.setComplemento(cliente.getComplemento());
        pendente.setAtivo(cliente.isAtivo());
        pendente.setAceitouTermos(cliente.isAceitouTermos());
        pendente.setStatusCadastro(StatusCadastro.PENDENTE);
        pendente.setMotivoRecusa(null);

        ClientePendente salvo = clientePendenteRepository.save(pendente);

        return ResponseEntity.ok().body(
                Map.of(
                        "mensagem", "✅ Registro recebido. Aguarde liberação do administrador.",
                        "registro", salvo
                )
        );
    }

    @GetMapping("/por-cpf/{cpf}")
    public ResponseEntity<?> buscarClientePorCpf(@PathVariable String cpf) {
        return clienteRepository.findByCpf(cpf)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/pendentes")
    public ResponseEntity<?> listarPendentes(@RequestParam String adminCpf) {
        if (!isAdministrador(adminCpf)) {
            return ResponseEntity.status(403).body("Apenas administrador pode visualizar pendências.");
        }

        List<ClientePendente> pendentes = clientePendenteRepository.findByStatusCadastroOrderByIdAsc(StatusCadastro.PENDENTE);
        return ResponseEntity.ok(pendentes);
    }

    @GetMapping("/pendentes/quantidade")
    public ResponseEntity<?> quantidadePendentes(@RequestParam String adminCpf) {
        if (!isAdministrador(adminCpf)) {
            return ResponseEntity.status(403).body("Apenas administrador pode visualizar pendências.");
        }

        long quantidade = clientePendenteRepository.countByStatusCadastro(StatusCadastro.PENDENTE);
        return ResponseEntity.ok(Map.of("quantidade", quantidade));
    }

    @PutMapping("/pendentes/{id}/aprovar")
    public ResponseEntity<?> aprovarCadastro(@PathVariable Long id, @RequestParam String adminCpf) {
        if (!isAdministrador(adminCpf)) {
            return ResponseEntity.status(403).body("Apenas administrador pode aprovar registros.");
        }

        Optional<ClientePendente> pendenteOpt = clientePendenteRepository.findById(id);
        if (pendenteOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        ClientePendente pendente = pendenteOpt.get();
        if (pendente.getStatusCadastro() != StatusCadastro.PENDENTE) {
            return ResponseEntity.badRequest().body("Registro já foi processado.");
        }

        if (clienteRepository.existsByCpf(pendente.getCpf())) {
            pendente.setStatusCadastro(StatusCadastro.APROVADO);
            pendente.setMotivoRecusa(null);
            clientePendenteRepository.save(pendente);
            return ResponseEntity.ok("Registro já estava aprovado na base definitiva.");
        }

        Cliente cliente = new Cliente();
        cliente.setNome(pendente.getNome());
        cliente.setTelefone(pendente.getTelefone());
        cliente.setEmail(pendente.getEmail());
        cliente.setCpf(pendente.getCpf());
        cliente.setSexo(pendente.getSexo());
        cliente.setSenha(pendente.getSenha());
        cliente.setCep(pendente.getCep());
        cliente.setCidade(pendente.getCidade());
        cliente.setBairro(pendente.getBairro());
        cliente.setNumero(pendente.getNumero());
        cliente.setComplemento(pendente.getComplemento());
        cliente.setAtivo(pendente.isAtivo());
        cliente.setAceitouTermos(pendente.isAceitouTermos());
        cliente.setAdministrador(false);
        clienteRepository.save(cliente);

        if (usuarioRepository.findByLogin(pendente.getCpf()).isEmpty()) {
            Usuario usuario = new Usuario(pendente.getCpf(), pendente.getSenha());
            usuarioRepository.save(usuario);
        }

        pendente.setStatusCadastro(StatusCadastro.APROVADO);
        pendente.setMotivoRecusa(null);
        clientePendenteRepository.save(pendente);

        return ResponseEntity.ok("✅ Registro aprovado com sucesso.");
    }

    @PutMapping("/pendentes/{id}/recusar")
    public ResponseEntity<?> recusarCadastro(@PathVariable Long id,
                                             @RequestParam String adminCpf,
                                             @RequestParam(required = false) String motivo) {
        if (!isAdministrador(adminCpf)) {
            return ResponseEntity.status(403).body("Apenas administrador pode recusar registros.");
        }

        Optional<ClientePendente> pendenteOpt = clientePendenteRepository.findById(id);
        if (pendenteOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        ClientePendente pendente = pendenteOpt.get();
        if (pendente.getStatusCadastro() != StatusCadastro.PENDENTE) {
            return ResponseEntity.badRequest().body("Registro já foi processado.");
        }

        pendente.setStatusCadastro(StatusCadastro.RECUSADO);
        pendente.setMotivoRecusa((motivo == null || motivo.isBlank()) ? "Registro recusado pelo administrador." : motivo);
        clientePendenteRepository.save(pendente);

        return ResponseEntity.ok("⛔ Registro recusado.");
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> buscarCliente(@PathVariable Long id) {
        return clienteRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/mostrar")
    public ResponseEntity<List<Cliente>> listarTodos() {
        List<Cliente> clientes = clienteRepository.findAll();
        return ResponseEntity.ok(clientes);
    }

    @PutMapping("/atualizar/{cpf}")
    public ResponseEntity<?> atualizarCliente(@PathVariable String cpf,
                                              @RequestParam String requesterCpf,
                                              @RequestBody Cliente clienteAtualizado) {
        Optional<Cliente> clienteExistente = clienteRepository.findByCpf(cpf);

        if (clienteExistente.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        boolean requesterAdmin = isAdministrador(requesterCpf);
        boolean editandoProprioPerfil = requesterCpf.equals(cpf);
        if (!requesterAdmin && !editandoProprioPerfil) {
            return ResponseEntity.status(403).body("Sem permissão para editar este usuário.");
        }

        Cliente cliente = clienteExistente.get();

        // Atualiza os campos
        cliente.setNome(clienteAtualizado.getNome());
        cliente.setTelefone(clienteAtualizado.getTelefone());
        cliente.setEmail(clienteAtualizado.getEmail());
        cliente.setSexo(clienteAtualizado.getSexo());
        cliente.setSenha(clienteAtualizado.getSenha());
        cliente.setCep(clienteAtualizado.getCep());
        cliente.setCidade(clienteAtualizado.getCidade());
        cliente.setBairro(clienteAtualizado.getBairro());
        cliente.setNumero(clienteAtualizado.getNumero());
        cliente.setComplemento(clienteAtualizado.getComplemento());
        cliente.setAtivo(clienteAtualizado.isAtivo());
        cliente.setAceitouTermos(clienteAtualizado.isAceitouTermos());
        if (requesterAdmin) {
            cliente.setAdministrador(clienteAtualizado.isAdministrador());
        }

        clienteRepository.save(cliente);

        Optional<Usuario> usuarioOpt = usuarioRepository.findByLogin(cpf);
        if (usuarioOpt.isPresent()) {
            Usuario usuario = usuarioOpt.get();
            usuario.setSenha(clienteAtualizado.getSenha());
            usuarioRepository.save(usuario);
        }

        return ResponseEntity.ok(cliente);
    }

    @DeleteMapping("/{cpf}")
    public ResponseEntity<?> excluirCliente(@PathVariable String cpf, @RequestParam String requesterCpf) {
        if (!isAdministrador(requesterCpf)) {
            return ResponseEntity.status(403).body("Apenas administrador pode remover usuários.");
        }

        Optional<Cliente> clienteOpt = clienteRepository.findByCpf(cpf);
        if (clienteOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        clienteRepository.delete(clienteOpt.get());
        usuarioRepository.findByLogin(cpf).ifPresent(usuarioRepository::delete);

        return ResponseEntity.ok("✅ Cliente removido com sucesso.");
    }

    private boolean isAdministrador(String cpf) {
        return clienteRepository.findByCpf(cpf)
                .map(Cliente::isAdministrador)
                .orElse(false);
    }

}

