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
  late final TextEditingController _inicioRelatorioController;
  late final TextEditingController _fimRelatorioController;
  String _tabelaRelatorio = 'sensor_data';
  final Set<String> _secoesRelatorio = {
    'resumo',
    'graficos',
    'saude',
    'alertas',
    'recomendacoes',
  };
  final List<_MensagemChat> _mensagens = [
    const _MensagemChat(
      texto:
          'Olá! Posso consultar dados, cultivos, alertas e relatórios da unidade, além de ajudar com plantas.',
      doUsuario: false,
    ),
  ];
  final Set<int> _cadastrosSalvos = {};
  final Set<int> _cadastrosCancelados = {};
  final Set<int> _cadastrosProcessando = {};
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    final inicio = hoje.subtract(const Duration(days: 30));
    _inicioRelatorioController = TextEditingController(
      text: inicio.toIso8601String().substring(0, 10),
    );
    _fimRelatorioController = TextEditingController(
      text: hoje.toIso8601String().substring(0, 10),
    );
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    _plantaController.dispose();
    _umidadeController.dispose();
    _temperaturaController.dispose();
    _scrollController.dispose();
    _inicioRelatorioController.dispose();
    _fimRelatorioController.dispose();
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

    final textoExibido =
        pergunta.isEmpty ? 'Como cuidar de $planta?' : pergunta;
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
              .skip(_mensagens.length > 12 ? _mensagens.length - 12 : 0)
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
      final relatorio = dados['relatorio']?.toString() ??
          dados['analiseLocal']?.toString() ??
          'Não foi possível gerar um relatório.';
      final fontes = (dados['fontes'] is List
              ? dados['fontes'] as List
              : const <dynamic>[])
          .whereType<Map>()
          .map((fonte) => fonte['titulo']?.toString())
          .whereType<String>()
          .toList();
      final complemento =
          fontes.isEmpty ? '' : '\n\nFontes: ${fontes.join(', ')}.';
      final arquivoPath = dados['arquivoUrl']?.toString();
      Uri? arquivoUri;
      if (arquivoPath != null && arquivoPath.startsWith('/')) {
        arquivoUri = Uri.parse(baseUrl).resolve(arquivoPath);
      }
      final fontesExternas = (dados['fontes'] is List
              ? dados['fontes'] as List
              : const <dynamic>[])
          .whereType<Map>()
          .map((fonte) => Map<String, dynamic>.from(fonte))
          .toList();
      final propostaCadastro = _extrairPropostaCadastro(dados);
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
                        _detalhesCadastro(mensagem.cadastroPendente!),
                        if (_cadastrosSalvos.contains(index))
                          const Text('Cultivo cadastrado desabilitado.')
                        else if (_cadastrosCancelados.contains(index))
                          const Text('Proposta de cadastro cancelada.')
                        else ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _cadastrosProcessando.contains(index)
                                  ? null
                                  : () => _confirmarCadastro(index, mensagem),
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                mensagem.cadastroPendente?[
                                            'estimativaNaoVerificada'] ==
                                        true
                                    ? 'Assumir o risco e cadastrar'
                                    : mensagem.cadastroPendente?[
                                                'umidadeSoloEstimada'] ==
                                            true
                                        ? 'Aceitar estimativa e cadastrar'
                                        : 'Confirmar e salvar cultivo',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _cadastrosProcessando.contains(index)
                                  ? null
                                  : () => setState(
                                        () => _cadastrosCancelados.add(index),
                                      ),
                              child: const Text('Cancelar proposta'),
                            ),
                          ),
                        ],
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
                  PopupMenuButton<String>(
                    tooltip: 'Relatorio personalizado',
                    onSelected: (formato) =>
                        _abrirConfiguracaoRelatorio(formato),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf_outlined),
                          title: Text('Relatorio personalizado'),
                          subtitle: Text(
                            'PDF com graficos e recomendacoes',
                          ),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'csv',
                        child: ListTile(
                          leading: Icon(Icons.table_chart_outlined),
                          title: Text('Relatorio personalizado'),
                          subtitle: Text(
                            'CSV com dados consolidados para criar graficos no Excel',
                          ),
                          dense: true,
                        ),
                      ),
                    ],
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F5EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFB6DCCA)),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF0E7D63),
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

  Future<void> _abrirConfiguracaoRelatorio(String formato) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    formato == 'pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.table_chart_outlined,
                    color: const Color(0xFF0E7D63),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formato == 'pdf'
                        ? 'Relatório personalizado em PDF'
                        : 'Relatório personalizado em CSV',
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conteúdo do relatório',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          _checkboxSecao(
                            setDialogState,
                            'resumo',
                            'Resumo executivo',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'graficos',
                            'Gráficos',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'temperatura',
                            'Temperatura',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'umidade',
                            'Umidade do ar',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'solo',
                            'Umidade do solo',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'saude',
                            'Saúde da planta',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'alertas',
                            'Alertas e erros',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'tendencias',
                            'Tendências',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'recomendacoes',
                            'Recomendações',
                          ),
                          _checkboxSecao(
                            setDialogState,
                            'dados',
                            'Dados detalhados',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _tabelaRelatorio,
                        decoration: const InputDecoration(
                          labelText: 'Fonte dos dados',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'sensor_data',
                            child: Text('Sensores — leituras detalhadas'),
                          ),
                          DropdownMenuItem(
                            value: 'relatorio_diario',
                            child: Text(
                              'Histórico consolidado — médias diárias',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'alertas',
                            child: Text('Alertas gerados pela unidade'),
                          ),
                        ],
                        onChanged: (valor) {
                          setDialogState(() {
                            _tabelaRelatorio = valor ?? 'sensor_data';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inicioRelatorioController,
                              decoration: const InputDecoration(
                                labelText: 'Início AAAA-MM-DD',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _fimRelatorioController,
                              decoration: const InputDecoration(
                                labelText: 'Fim AAAA-MM-DD',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              final hoje = DateTime.now();
                              final inicio = hoje.subtract(
                                const Duration(days: 6),
                              );
                              setDialogState(() {
                                _inicioRelatorioController.text =
                                    inicio.toIso8601String().substring(0, 10);
                                _fimRelatorioController.text =
                                    hoje.toIso8601String().substring(0, 10);
                              });
                            },
                            child: const Text('Últimos 7 dias'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              final hoje = DateTime.now();
                              final inicio = hoje.subtract(
                                const Duration(days: 29),
                              );
                              setDialogState(() {
                                _inicioRelatorioController.text =
                                    inicio.toIso8601String().substring(0, 10);
                                _fimRelatorioController.text =
                                    hoje.toIso8601String().substring(0, 10);
                              });
                            },
                            child: const Text('Últimos 30 dias'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              final hoje = DateTime.now();
                              final inicio = hoje.subtract(
                                const Duration(days: 89),
                              );
                              setDialogState(() {
                                _inicioRelatorioController.text =
                                    inicio.toIso8601String().substring(0, 10);
                                _fimRelatorioController.text =
                                    hoje.toIso8601String().substring(0, 10);
                              });
                            },
                            child: const Text('Trimestre'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              final hoje = DateTime.now();
                              final inicio = hoje.subtract(
                                const Duration(days: 364),
                              );
                              setDialogState(() {
                                _inicioRelatorioController.text =
                                    inicio.toIso8601String().substring(0, 10);
                                _fimRelatorioController.text =
                                    hoje.toIso8601String().substring(0, 10);
                              });
                            },
                            child: const Text('Último ano'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text('Gerar ${formato.toUpperCase()}'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmou == true) {
      await _gerarRelatorioPersonalizado(formato);
    }
  }

  Future<void> _gerarRelatorioPersonalizado(String formato) async {
    final inicio = _inicioRelatorioController.text.trim();
    final fim = _fimRelatorioController.text.trim();
    final inicioData = DateTime.tryParse(inicio);
    final fimData = DateTime.tryParse(fim);

    if (inicioData == null || fimData == null || fimData.isBefore(inicioData)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um período válido no formato AAAA-MM-DD.'),
        ),
      );
      return;
    }
    setState(() {
      _mensagens.add(
        _MensagemChat(
          texto:
              'Gerar relatório personalizado ${formato.toUpperCase()}, de $inicio até $fim.',
          doUsuario: true,
        ),
      );
      _carregando = true;
    });
    _rolarParaFim();

    try {
      final baseUrl = await ApiSettings.obterUrlApi();
      final parametros = Uri(
        queryParameters: {
          'tabela': _tabelaRelatorio,
          'inicio': inicio,
          'fim': fim,
          'formato': formato,
          'template': 'personalizado',
          'secoes': _secoesRelatorio.join(','),
        },
      );
      final uri = Uri.parse(
        baseUrl,
      ).resolve('/api/ia/relatorio${parametros.toString()}');
      if (mounted) {
        setState(() {
          final nome =
              'estufa_${_tabelaRelatorio}_personalizado_${inicio}_a_$fim.$formato';
          _mensagens.add(
            _MensagemChat(
              texto:
                  'Relatório profissional pronto. Inclui resumo, indicadores, recomendações'
                  '${formato == 'pdf' ? ', gráficos da evolução e tabela consolidada.' : ' e séries organizadas para planilhas.'}',
              doUsuario: false,
              arquivoUri: uri,
              arquivoNome: nome,
            ),
          );
        });
        _rolarParaFim();
      }
    } catch (erro) {
      if (mounted) {
        setState(() {
          _mensagens.add(
            _MensagemChat(
              texto:
                  'Não foi possível preparar o relatório. ${erro.toString().replaceFirst('Exception: ', '')}',
              doUsuario: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
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

  Map<String, dynamic>? _extrairPropostaCadastro(
    Map<String, dynamic> resposta,
  ) {
    final valor = resposta['cadastroPendente'] ?? resposta['acaoPendente'];
    if (valor is! Map) return null;

    final proposta = Map<String, dynamic>.from(valor);
    final cultivo = proposta['cultivo'];
    if (cultivo is Map) {
      final dadosCultivo = _validarDadosCultivo(
        Map<String, dynamic>.from(cultivo),
      );
      if (dadosCultivo == null) return null;
      proposta['cultivo'] = dadosCultivo;
      return proposta;
    }

    final dadosCultivo = _validarDadosCultivo(proposta);
    if (dadosCultivo == null) return null;
    return {
      'cultivo': dadosCultivo,
      'origem': proposta['origem'] ?? 'não informada',
      'fontes': proposta['fontes'] ?? const <dynamic>[],
    };
  }

  Map<String, dynamic>? _validarDadosCultivo(Map<String, dynamic> dados) {
    final nome = dados['nome']?.toString().trim() ?? '';
    final tipo = dados['tipo']?.toString().trim() ?? '';
    const camposNumericos = [
      'temperaturaMinima',
      'temperaturaMaxima',
      'umidadeMinima',
      'umidadeMaxima',
      'umidadeSoloMinima',
      'umidadeSoloMaxima',
    ];
    final valores = <String, double>{};
    for (final campo in camposNumericos) {
      final valor = dados[campo];
      final numero = valor is num
          ? valor.toDouble()
          : double.tryParse(valor?.toString().replaceAll(',', '.') ?? '');
      if (numero == null || !numero.isFinite) return null;
      valores[campo] = numero;
    }

    final temperaturaMinima = valores['temperaturaMinima']!;
    final temperaturaMaxima = valores['temperaturaMaxima']!;
    final umidadeMinima = valores['umidadeMinima']!;
    final umidadeMaxima = valores['umidadeMaxima']!;
    final soloMinimo = valores['umidadeSoloMinima']!;
    final soloMaximo = valores['umidadeSoloMaxima']!;
    if (nome.isEmpty ||
        tipo.isEmpty ||
        temperaturaMinima < 0 ||
        temperaturaMaxima < temperaturaMinima ||
        umidadeMinima < 0 ||
        umidadeMaxima > 100 ||
        umidadeMaxima < umidadeMinima ||
        soloMinimo < 0 ||
        soloMaximo > 100 ||
        soloMaximo < soloMinimo) {
      return null;
    }

    return {'nome': nome, 'tipo': tipo, ...valores, 'habilitada': false};
  }

  Future<void> _confirmarCadastro(int indice, _MensagemChat mensagem) async {
    if (_cadastrosProcessando.contains(indice) ||
        _cadastrosSalvos.contains(indice) ||
        _cadastrosCancelados.contains(indice)) {
      return;
    }
    final proposta = mensagem.cadastroPendente;
    final cultivo = proposta?['cultivo'];
    if (cultivo is! Map) return;
    final dadosCultivo = _validarDadosCultivo(
      Map<String, dynamic>.from(cultivo),
    );
    if (dadosCultivo == null) {
      setState(() {
        _cadastrosCancelados.add(indice);
        _mensagens.add(
          const _MensagemChat(
            texto:
                'Não foi possível cadastrar: a proposta está incompleta ou contém faixas inválidas. Solicite uma nova proposta com os valores corretos.',
            doUsuario: false,
          ),
        );
      });
      _rolarParaFim();
      return;
    }
    setState(() => _cadastrosProcessando.add(indice));
    try {
      final baseUrl = await ApiSettings.obterUrlApi();
      final token = await _secureStorage.read(key: 'estufa_jwt');
      if (!mounted) return;
      final resposta = await http.post(
        Uri.parse(baseUrl).resolve('/api/cultivos'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dadosCultivo),
      );
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
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
        setState(() {
          _mensagens.add(
            _MensagemChat(
              texto:
                  'Não foi possível salvar o cultivo. ${erro.toString().replaceFirst('Exception: ', '')}',
              doUsuario: false,
            ),
          );
        });
        _rolarParaFim();
      }
    } finally {
      if (mounted) {
        setState(() => _cadastrosProcessando.remove(indice));
      }
    }
  }

  Widget _detalhesCadastro(Map<String, dynamic> proposta) {
    final cultivo = proposta['cultivo'];
    if (cultivo is! Map) {
      return const Text('A proposta recebida está incompleta.');
    }
    final dados = Map<String, dynamic>.from(cultivo);
    final estimativaNaoVerificada = proposta['estimativaNaoVerificada'] == true;
    final possuiEstimativa =
        estimativaNaoVerificada || proposta['umidadeSoloEstimada'] == true;
    return Text(
      'Proposta: ${dados['nome']} (${dados['tipo']})\n'
      '${estimativaNaoVerificada ? '⚠️ HÁ FAIXAS ESTIMADAS, SEM VALIDAÇÃO TÉCNICA\n' : ''}'
      'Temperatura: ${dados['temperaturaMinima']}–${dados['temperaturaMaxima']} °C\n'
      'Umidade do ar: ${dados['umidadeMinima']}–${dados['umidadeMaxima']} %\n'
      'Umidade do solo: ${dados['umidadeSoloMinima']}–${dados['umidadeSoloMaxima']} %\n'
      'Origem: ${proposta['origem'] ?? 'não informada'}'
      '${possuiEstimativa ? '\n\nAtenção: ${proposta['observacao'] ?? 'as faixas são estimadas e devem ser validadas.'}\nAo confirmar o cadastro, você assume o risco de usar esses valores.' : ''}',
    );
  }

  Widget _checkboxSecao(
    StateSetter setDialogState,
    String chave,
    String titulo,
  ) {
    return FilterChip(
      selected: _secoesRelatorio.contains(chave),
      label: Text(titulo),
      selectedColor: const Color(0xFFBDE5CE),
      checkmarkColor: const Color(0xFF0E7D63),
      onSelected: (selecionado) {
        setDialogState(() {
          if (selecionado) {
            _secoesRelatorio.add(chave);
          } else {
            _secoesRelatorio.remove(chave);
          }
        });
      },
    );
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
