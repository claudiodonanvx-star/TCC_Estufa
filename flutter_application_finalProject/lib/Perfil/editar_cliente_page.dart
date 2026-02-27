import 'package:flutter/material.dart';
import 'package:flutter_application_1/cadastro/cliente.dart';
import 'cliente_service.dart';

class EditarClientePage extends StatefulWidget {
  final Cliente cliente;
  final String requesterCpf;
  final bool administradorLogado;

  const EditarClientePage({
    super.key,
    required this.cliente,
    required this.requesterCpf,
    required this.administradorLogado,
  });

  @override
  State<EditarClientePage> createState() => _EditarClientePageState();
}

class _EditarClientePageState extends State<EditarClientePage> {
  late TextEditingController nomeController;
  late TextEditingController telefoneController;
  late TextEditingController emailController;
  late TextEditingController sexoController;
  late TextEditingController senhaController;
  late TextEditingController cepController;
  late TextEditingController cidadeController;
  late TextEditingController bairroController;
  late TextEditingController numeroController;
  late TextEditingController complementoController;
  bool ativo = false;
  bool aceitouTermos = false;
  bool administrador = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    nomeController = TextEditingController(text: c.nome);
    telefoneController = TextEditingController(text: c.telefone);
    emailController = TextEditingController(text: c.email);
    sexoController = TextEditingController(text: c.sexo);
    senhaController = TextEditingController(text: c.senha);
    cepController = TextEditingController(text: c.cep);
    cidadeController = TextEditingController(text: c.cidade);
    bairroController = TextEditingController(text: c.bairro);
    numeroController = TextEditingController(text: c.numero);
    complementoController = TextEditingController(text: c.complemento);
    ativo = c.ativo;
    aceitouTermos = c.aceitouTermos;
    administrador = c.administrador;
  }

  void salvar() async {
    final clienteAtualizado = Cliente(
      nome: nomeController.text,
      telefone: telefoneController.text,
      email: emailController.text,
      cpf: widget.cliente.cpf,
      sexo: sexoController.text,
      senha: senhaController.text,
      cep: cepController.text,
      cidade: cidadeController.text,
      bairro: bairroController.text,
      numero: numeroController.text,
      complemento: complementoController.text,
      ativo: ativo,
      aceitouTermos: aceitouTermos,
      administrador: administrador,
    );

    final sucesso = await ClienteService.atualizarCliente(
      clienteAtualizado,
      widget.requesterCpf,
    );
    if (!mounted) {
      return;
    }
    if (sucesso) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Cliente')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nomeController, decoration: InputDecoration(labelText: 'Nome')),
            TextField(controller: telefoneController, decoration: InputDecoration(labelText: 'Telefone')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: sexoController, decoration: InputDecoration(labelText: 'Sexo')),
            TextField(controller: senhaController, decoration: InputDecoration(labelText: 'Senha')),
            TextField(controller: cepController, decoration: InputDecoration(labelText: 'CEP')),
            TextField(controller: cidadeController, decoration: InputDecoration(labelText: 'Cidade')),
            TextField(controller: bairroController, decoration: InputDecoration(labelText: 'Bairro')),
            TextField(controller: numeroController, decoration: InputDecoration(labelText: 'Número')),
            TextField(controller: complementoController, decoration: InputDecoration(labelText: 'Complemento')),
            SwitchListTile(
              title: Text('Ativo'),
              value: ativo,
              onChanged: (val) => setState(() => ativo = val),
            ),
            SwitchListTile(
              title: Text('Aceitou Termos'),
              value: aceitouTermos,
              onChanged: (val) => setState(() => aceitouTermos = val),
            ),
            if (widget.administradorLogado)
              SwitchListTile(
                title: Text('Administrador'),
                value: administrador,
                onChanged: (val) => setState(() => administrador = val),
              ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: salvar, child: Text('Salvar')),
          ],
        ),
      ),
    );
  }
}