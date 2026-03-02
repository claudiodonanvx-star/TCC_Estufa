import 'package:flutter/material.dart';
import 'package:flutter_application_1/cadastro/api_service.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:flutter_application_1/main.dart';
import 'cliente.dart';
//import 'usuario.dart';

void main() {
  runApp(MaterialApp(home: Telainicial(), debugShowCheckedModeBanner: false));
}

class Telainicial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.green[300],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/imagesE/logo_colorido.png',
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "EstufaSmart",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.support_agent),
                  tooltip: 'Atendimento',
                  onPressed: () {
                    final TextEditingController duvidaController =
                        TextEditingController();

                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Atendimento ao Cliente'),
                            content: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.60,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Container de E-mails
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '📧 E‑mails:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black,
                                          ),
                                          Text('• suporte@estufasmart.com'),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black,
                                          ),
                                          Text('• contato@estufasmart.com'),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black,
                                          ),
                                          Text('• sac@estufasmart.com'),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black,
                                          ),
                                          Text('• financeiro@estufasmart.com'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '📞 Telefones:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black,
                                          ),
                                          Text('• (11) 4002‑8922'),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.black,
                                          ),
                                          Text('• (19) 99999‑1234'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Divider(thickness: 1, color: Colors.black),
                                    const Text(
                                      '✉️ Deixe sua dúvida:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: duvidaController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: 'Escreva sua dúvida aqui...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  final texto = duvidaController.text.trim();
                                  if (texto.isNotEmpty) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Dúvida enviada!'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Digite a dúvida antes de enviar.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Enviar'),
                              ),
                              TextButton(
                                onPressed:
                                    () =>
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop(),
                                child: const Text('Fechar'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Cultive o futuro hoje ",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 20),

                        Text(
                          "Tempestades passam. Mas quem é autoregulável floresce em qualquer tempo.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 50),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start, // alinha os botões à esquerda
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CadastroClientes(),
                                  ),
                                );
                              },
                              child: Text(
                                "Cadastro",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                minimumSize: Size(140, 50),
                                textStyle: TextStyle(fontSize: 18),
                              ),
                            ),
                            SizedBox(height: 16), // espaço entre os botões
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Login",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                minimumSize: Size(144, 50),
                                textStyle: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 600,
                        height: 600,
                        child: Image.asset("assets/imagesE/estu.png"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final String text;
  NavItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }
}

// ---------------------- LoginScreen ----------------------

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool? conexaoOk;
  String? ipExterno;

  @override
  void initState() {
    super.initState();
    carregarIpETestar();
  }

  Future<void> carregarIpETestar() async {
    final ip = await IpUtil.carregarIp();
    if (ip == null) {
      setState(() {
        conexaoOk = false;
        ipExterno = null;
      });
      return;
    }

    final sucesso = await ApiService.testarConexao(ip);
    setState(() {
      conexaoOk = sucesso;
      ipExterno = ip;
    });

    print('🔌 IP testado: $ip → ${sucesso ? "Conexão OK" : "Falhou"}');
  }

  void _verificarLogin() async {
    if (conexaoOk != true || ipExterno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conexão com a API falhou. Verifique o IP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final sucesso = await ApiService.autenticarUsuario(
        ipExterno!,
        _usuarioController.text,
        _senhaController.text,
      );

      if (sucesso.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bem-vindo, ${_usuarioController.text}!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => HomePage(
                      cpfLogado:
                          sucesso.cpf ??
                          _usuarioController.text.replaceAll(RegExp(r'\D'), ''),
                      administrador: sucesso.administrador,
                      pendenciasAprovacao: sucesso.pendenciasAprovacao,
                    ),
              ),
            );
          }
        });
      } else {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text('Acesso Negado'),
                content: Text(sucesso.mensagem),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Widget iconeConexao() {
    if (conexaoOk == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Icon(
        Icons.lightbulb,
        color: conexaoOk! ? Colors.green : Colors.grey,
        size: 48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: Column(
        children: [
          iconeConexao(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/imagesE/login.gif', width: 200),
                          SizedBox(height: 40),
                          TextFormField(
                            controller: _usuarioController,
                            decoration: InputDecoration(
                              labelText: 'Usuário',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Usuário é obrigatório'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Senha é obrigatória';
                              if (value.length < 3)
                                return 'Senha deve ter no mínimo 3 caracteres';
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _verificarLogin,
                            child: Text(
                              'Entrar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- CadastroClientes ----------------------

class CadastroClientes extends StatefulWidget {
  @override
  _CadastroClientesState createState() => _CadastroClientesState();
}

class _CadastroClientesState extends State<CadastroClientes> {
  final _formKey = GlobalKey<FormState>();
  final List<Cliente> _clientes = [];
  bool? conexaoOk;
  String? ipExterno;

  @override
  void initState() {
    super.initState();
    carregarIpETestar();
  }

  Future<void> carregarIpETestar() async {
    final ip = await IpUtil.carregarIp();
    if (ip == null) {
      setState(() {
        conexaoOk = false;
        ipExterno = null;
      });
      return;
    }

    final sucesso = await ApiService.testarConexao(ip);
    setState(() {
      conexaoOk = sucesso;
      ipExterno = ip;
    });

    print('🔌 IP testado: $ip → ${sucesso ? "Conexão OK" : "Falhou"}');
  }

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();

  String _sexo = 'Masculino';
  bool _ativo = false;
  bool _aceitouTermos = false;

  void _limparCampos() {
    _formKey.currentState?.reset();
    _nomeController.clear();
    _telefoneController.clear();
    _emailController.clear();
    _cpfController.clear();
    _senhaController.clear();
    _cepController.clear();
    _cidadeController.clear();
    _bairroController.clear();
    _numeroController.clear();
    _complementoController.clear();

    setState(() {
      _sexo = 'Masculino';
      _ativo = false;
      _aceitouTermos = false;
    });
  }

  void _mostrarClientes() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clientes Cadastrados'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _clientes.map((cliente) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informações Pessoais', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Nome: ${cliente.nome}'),
                      Text('Telefone: ${cliente.telefone}'),
                      Text('Email: ${cliente.email}'),
                      Text('CPF: ${cliente.cpf}'),
                      Text('Sexo: ${cliente.sexo}'),
                      const Divider(),
                      const Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('CEP: ${cliente.cep}'),
                      Text('Cidade: ${cliente.cidade}'),
                      Text('Bairro: ${cliente.bairro}'),
                      Text('Número: ${cliente.numero}'),
                      if (cliente.complemento.isNotEmpty)
                        Text('Complemento: ${cliente.complemento}'),
                      const Divider(),
                      const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Ativo: ${cliente.ativo ? "Sim" : "Não"}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _cadastrarCliente() async {
    if (_formKey.currentState!.validate() && _aceitouTermos) {
      if (conexaoOk != true || ipExterno == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conexão com a API falhou. Verifique o IP.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Cliente novo = Cliente(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
        email: _emailController.text.trim(),
        cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
        sexo: _sexo,
        senha: _senhaController.text,
        cep: _cepController.text.replaceAll(RegExp(r'\D'), ''),
        cidade: _cidadeController.text.trim(),
        bairro: _bairroController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        ativo: _ativo,
        aceitouTermos: _aceitouTermos,
      );

      final resultado = await ApiService.cadastrarCliente(ipExterno!, novo);

      if (resultado != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Sucesso'),
            content: Text(resultado['mensagem'] ?? 'Cliente cadastrado!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        _limparCampos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar cliente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_aceitouTermos) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Atenção'),
          content: Text('Você deve aceitar os termos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: Text(
          'EstufaSmart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[300],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Informações Pessoais",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _nomeController,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Nome é obrigatório'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _telefoneController,
                            decoration: InputDecoration(
                              labelText: 'Telefone (00 00000-0000)',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              var digits = value.replaceAll(RegExp(r'\D'), '');
                              if (digits.length > 11)
                                digits = digits.substring(0, 11);

                              String fmt = digits;
                              if (digits.length >= 2) {
                                fmt = '${digits.substring(0, 2)} ';
                                if (digits.length >= 7) {
                                  fmt +=
                                      '${digits.substring(2, 7)}-${digits.substring(7)}';
                                } else if (digits.length > 2) {
                                  fmt += digits.substring(2);
                                }
                              }
                              _telefoneController.value = TextEditingValue(
                                text: fmt,
                                selection: TextSelection.collapsed(
                                  offset: fmt.length,
                                ),
                              );
                            },
                            validator:
                                (v) =>
                                    RegExp(
                                          r'^\d{2} \d{5}-\d{4}$',
                                        ).hasMatch(v ?? '')
                                        ? null
                                        : 'Telefone inválido',
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              const regex =
                                  r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$';
                              if (v == null || v.isEmpty)
                                return 'Email é obrigatório';
                              if (!RegExp(regex).hasMatch(v))
                                return 'Email inválido';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _cpfController,
                            decoration: InputDecoration(
                              labelText: 'CPF (000.000.000-00)',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              var digits = value.replaceAll(RegExp(r'\D'), '');
                              if (digits.length > 11)
                                digits = digits.substring(0, 11);

                              String fmt = digits;
                              if (digits.length >= 3) {
                                fmt = digits.substring(0, 3);
                                if (digits.length >= 6) {
                                  fmt += '.${digits.substring(3, 6)}';
                                  if (digits.length >= 9) {
                                    fmt += '.${digits.substring(6, 9)}';
                                    if (digits.length >= 10) {
                                      fmt += '-${digits.substring(9)}';
                                    }
                                  } else if (digits.length > 6) {
                                    fmt += '.${digits.substring(6)}';
                                  }
                                } else if (digits.length > 3) {
                                  fmt += '.${digits.substring(3)}';
                                }
                              }
                              _cpfController.value = TextEditingValue(
                                text: fmt,
                                selection: TextSelection.collapsed(
                                  offset: fmt.length,
                                ),
                              );
                            },
                            validator:
                                (v) =>
                                    RegExp(
                                          r'^\d{3}\.\d{3}\.\d{3}-\d{2}$',
                                        ).hasMatch(v ?? '')
                                        ? null
                                        : 'CPF inválido',
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Senha é obrigatória';
                              if (value.length < 3)
                                return 'Senha deve ter no mínimo 3 caracteres';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _sexo,
                            items:
                                ['Masculino', 'Feminino', 'Outro']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) => setState(() => _sexo = val!),
                            decoration: InputDecoration(
                              labelText: 'Sexo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Endereço",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _cepController,
                            decoration: InputDecoration(
                              labelText: 'CEP (00000-000)',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              var digits = value.replaceAll(RegExp(r'\D'), '');
                              if (digits.length > 8)
                                digits = digits.substring(0, 8);

                              String fmt = digits;
                              if (digits.length > 5) {
                                fmt =
                                    '${digits.substring(0, 5)}-${digits.substring(5)}';
                              }
                              _cepController.value = TextEditingValue(
                                text: fmt,
                                selection: TextSelection.collapsed(
                                  offset: fmt.length,
                                ),
                              );
                            },
                            validator:
                                (v) =>
                                    RegExp(r'^\d{5}-\d{3}$').hasMatch(v ?? '')
                                        ? null
                                        : 'CEP inválido',
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _cidadeController,
                            decoration: InputDecoration(
                              labelText: 'Cidade (ex: Limeira - SP)',
                              prefixIcon: Icon(Icons.location_city),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Cidade é obrigatória'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _bairroController,
                            decoration: InputDecoration(
                              labelText: 'Bairro',
                              prefixIcon: Icon(Icons.home_work),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Bairro é obrigatório'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _numeroController,
                            decoration: InputDecoration(
                              labelText: 'Número da casa',
                              prefixIcon: Icon(Icons.format_list_numbered),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Número é obrigatório'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _complementoController,
                            decoration: InputDecoration(
                              labelText: 'Complemento',
                              prefixIcon: Icon(Icons.edit),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(thickness: 1, color: Colors.black),
                    SwitchListTile(
                      title: Text('Ativo'),
                      value: _ativo,
                      onChanged: (val) => setState(() => _ativo = val),
                    ),
                    CheckboxListTile(
                      title: Text('Aceito os termos de uso'),
                      value: _aceitouTermos,
                      onChanged:
                          (val) =>
                              setState(() => _aceitouTermos = val ?? false),
                    ),
                    Divider(thickness: 1, color: Colors.black),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate() &&
                                _aceitouTermos) {
                              _cadastrarCliente();
                            } else if (!_aceitouTermos) {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: Text('Atenção'),
                                      content: Text(
                                        'Você deve aceitar os termos.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('Entendi'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          },
                          child: Text('Cadastrar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Vermelho claro
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            minimumSize: Size(140, 50),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          onPressed: _limparCampos,
                          child: const Text(
                            'Limpar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Azul claro
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            minimumSize: Size(140, 50),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          onPressed: _mostrarClientes,
                          child: const Text(
                            'Mostrar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
