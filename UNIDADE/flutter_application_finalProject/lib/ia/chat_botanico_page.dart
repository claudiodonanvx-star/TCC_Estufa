import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/cadastro/api_settings.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:flutter_application_1/ia/ferramentas_internas.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ChatBotanicoPage extends StatefulWidget {
  const ChatBotanicoPage({super.key});

  @override
  State<ChatBotanicoPage> createState() => _ChatBotanicoPageState();
}

class _ChatBotanicoPageState extends State<ChatBotanicoPage> {
  static const _secureStorage = FlutterSecureStorage();
  final _perguntaController = TextEditingController();
  final _plantaController = TextEditingController();
  final _umidadeController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_MensagemChat> _mensagens = [
    const _MensagemChat(
      texto:
          'Olá! Posso consultar dados, cultivos, alertas e relatórios da unidade, além de ajudar com plantas.',
      doUsuario: false,
    ),
  ];
  final Set<int> _cadastrosSalvos = {};
  bool _carregando = false;

  @override
  void dispose() {
    _perguntaController.dispose();
    _plantaController.dispose();
    _umidadeController.dispose();
    _temperaturaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final planta = _plantaController.text.trim();
    if (pergunta.isEmpty && planta.isEmpty) {
      setState(() {
        _mensagens.add(
          const _MensagemChat(
            texto: 'Digite uma planta ou uma pergunta para começar.',
            doUsuario: false,
          ),
        );
      });
      return;
    }

    final textoExibido = pergunta.isEmpty
        ? 'Como cuidar de $planta?'
        : pergunta;
    setState(() {
      _mensagens.add(_MensagemChat(texto: textoExibido, doUsuario: true));
      _carregando = true;
    });
    _perguntaController.clear();
    _rolarParaFim();

    try {
      final ferramenta = FerramentaInterna.interpretar(textoExibido);
      if (ferramenta != null && ferramenta.executarLocalmente) {
        if (ferramenta.exigeConfirmacao &&
            !await _confirmarFerramenta(ferramenta)) {
          if (mounted) {
            setState(() {
              _mensagens.add(
                const _MensagemChat(
                  texto: 'A solicitação foi cancelada.',
                  doUsuario: false,
                ),
              );
            });
          }
          return;
        }
        final baseUrl = await IpUtil.carregarIp();
        if (baseUrl == null || baseUrl.isEmpty) {
          throw Exception('Não foi possível localizar a API da unidade.');
        }
        final resultado = await ferramenta.executar(baseUrl);
        if (mounted) {
          setState(() {
            _mensagens.add(_MensagemChat(texto: resultado, doUsuario: false));
          });
        }
        return;
      }

      final baseUrl = await ApiSettings.obterUrlApi();
      final token = await _secureStorage.read(key: 'estufa_jwt');
      final resposta = await http.post(
        Uri.parse('$baseUrl/api/ia/consulta-planta'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'planta': planta,
          'pergunta': pergunta,
          'umidadeAtual': double.tryParse(_umidadeController.text.trim()),
          'temperaturaAtual': double.tryParse(
            _temperaturaController.text.trim(),
          ),
          'historico': _mensagens
              .take(12)
              .map(
                (mensagem) => {
                  'papel': mensagem.doUsuario ? 'usuario' : 'agente',
                  'texto': mensagem.texto,
                },
              )
              .toList(),
        }),
      );
      Map<String, dynamic> dados = {};
      if (resposta.body.trim().isNotEmpty) {
        try {
          dados = jsonDecode(resposta.body) as Map<String, dynamic>;
        } catch (_) {
          dados = {'mensagem': 'A API retornou uma resposta inválida.'};
        }
      }
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception(
          resposta.statusCode == 404
              ? 'A consulta botânica ainda não foi publicada no servidor.'
              : dados['mensagem'] ?? 'A API recusou a consulta.',
        );
      }
      final relatorio =
          dados['relatorio']?.toString() ??
          dados['analiseLocal']?.toString() ??
          'Não foi possível gerar um relatório.';
      final fontes =
          (dados['fontes'] is List
                  ? dados['fontes'] as List
                  : const <dynamic>[])
              .whereType<Map>()
              .map((fonte) => fonte['titulo']?.toString())
              .whereType<String>()
              .toList();
      final complemento = fontes.isEmpty
          ? ''
          : '\n\nFontes: ${fontes.join(', ')}.';
      final arquivoPath = dados['arquivoUrl']?.toString();
      Uri? arquivoUri;
      if (arquivoPath != null && arquivoPath.startsWith('/')) {
        arquivoUri = Uri.parse(baseUrl).resolve(arquivoPath);
      }
      final fontesExternas =
          (dados['fontes'] is List
                  ? dados['fontes'] as List
                  : const <dynamic>[])
              .whereType<Map>()
              .map((fonte) => Map<String, dynamic>.from(fonte))
              .toList();
      final propostaCadastro = dados['cadastroPendente'] is Map
          ? Map<String, dynamic>.from(dados['cadastroPendente'] as Map)
          : null;
      if (mounted) {
        setState(() {
          _mensagens.add(
            _MensagemChat(
              texto: '$relatorio$complemento',
              doUsuario: false,
              arquivoUri: arquivoUri,
              arquivoNome: dados['arquivoNome']?.toString(),
              fontes: fontesExternas,
              cadastroPendente: propostaCadastro,
            ),
          );
        });
      }
    } catch (erro) {
      if (mounted) {
        setState(() {
          _mensagens.add(
            _MensagemChat(
              texto: erro.toString().replaceFirst('Exception: ', ''),
              doUsuario: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
        _rolarParaFim();
      }
    }
  }

  Future<bool> _confirmarFerramenta(FerramentaInterna ferramenta) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar comando'),
            content: Text(ferramenta.descricaoConfirmacao),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _mensagens.length,
            itemBuilder: (context, index) {
              final mensagem = _mensagens[index];
              return Align(
                alignment: mensagem.doUsuario
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: mensagem.doUsuario
                        ? const Color(0xFF0E7D63)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4EBDD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mensagem.texto,
                        style: TextStyle(
                          color: mensagem.doUsuario
                              ? Colors.white
                              : const Color(0xFF113128),
                          height: 1.35,
                        ),
                      ),
                      if (mensagem.arquivoUri != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _baixarArquivo(mensagem),
                          icon: const Icon(Icons.download_outlined),
                          label: Text(
                            'Baixar ${mensagem.arquivoNome ?? 'relatório'}',
                          ),
                        ),
                      ],
                      if (mensagem.fontes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Fontes externas consultadas:'),
                        for (final fonte in mensagem.fontes)
                          TextButton(
                            onPressed: () =>
                                _abrirFonte(fonte['url']?.toString()),
                            child: Text(fonte['titulo']?.toString() ?? 'Fonte'),
                          ),
                      ],
                      if (mensagem.cadastroPendente != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _cadastrosSalvos.contains(index)
                              ? null
                              : () => _confirmarCadastro(index, mensagem),
                          icon: const Icon(Icons.local_florist_outlined),
                          label: Text(
                            _cadastrosSalvos.contains(index)
                                ? 'Cultivo cadastrado'
                                : 'Confirmar cadastro do cultivo',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_carregando) const LinearProgressIndicator(minHeight: 2),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      _plantaController,
                      'Planta',
                      Icons.local_florist_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campo(
                      _umidadeController,
                      'Umidade %',
                      Icons.water_drop_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campo(
                      _temperaturaController,
                      'Temp. C',
                      Icons.thermostat_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _perguntaController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviarPergunta(),
                      decoration: const InputDecoration(
                        hintText: 'Ex.: qual umidade é ideal?',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar pergunta',
                    onPressed: _carregando ? null : _enviarPergunta,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _baixarArquivo(_MensagemChat mensagem) async {
    final uri = mensagem.arquivoUri;
    if (uri == null) return;

    try {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu) {
        throw Exception('Não foi possível abrir o download no navegador.');
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _abrirFonte(String? endereco) async {
    final uri = Uri.tryParse(endereco ?? '');
    if (uri == null || !uri.hasScheme) return;
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a fonte.')),
      );
    }
  }

  Future<void> _confirmarCadastro(int indice, _MensagemChat mensagem) async {
    final proposta = mensagem.cadastroPendente;
    final cultivo = proposta?['cultivo'];
    if (cultivo is! Map) return;
    final dadosCultivo = Map<String, dynamic>.from(cultivo);
    final confirmado =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cadastrar ${dadosCultivo['nome']}?'),
            content: Text(
              'Temperatura: ${dadosCultivo['temperaturaMinima']}–${dadosCultivo['temperaturaMaxima']} °C\n'
              'Umidade do ar: ${dadosCultivo['umidadeMinima']}–${dadosCultivo['umidadeMaxima']} %\n'
              'Umidade do solo: ${dadosCultivo['umidadeSoloMinima']}–${dadosCultivo['umidadeSoloMaxima']} %\n\n'
              'O cultivo será salvo desabilitado. Origem: ${proposta?['origem'] ?? 'não informada'}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmado || !mounted) return;

    try {
      final baseUrl = await ApiSettings.obterUrlApi();
      final token = await _secureStorage.read(key: 'estufa_jwt');
      if (!mounted) return;
      final resposta = await http.post(
        Uri.parse('$baseUrl/api/cultivos'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dadosCultivo),
      );
      if (resposta.statusCode != 201) {
        throw Exception(
          'A API recusou o cadastro (${resposta.statusCode}). ${resposta.body}',
        );
      }
      if (!mounted) return;
      setState(() {
        _cadastrosSalvos.add(indice);
        _mensagens.add(
          _MensagemChat(
            texto: 'Cultivo ${dadosCultivo['nome']} cadastrado desabilitado.',
            doUsuario: false,
          ),
        );
      });
      _rolarParaFim();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Widget _campo(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: label == 'Planta'
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

class _MensagemChat {
  final String texto;
  final bool doUsuario;
  final Uri? arquivoUri;
  final String? arquivoNome;
  final List<Map<String, dynamic>> fontes;
  final Map<String, dynamic>? cadastroPendente;

  const _MensagemChat({
    required this.texto,
    required this.doUsuario,
    this.arquivoUri,
    this.arquivoNome,
    this.fontes = const [],
    this.cadastroPendente,
  });
}
