import 'dart:async';
import 'package:flutter_application_1/cadastro/api_service.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/iot/api_service.dart';
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/Cultivo.dart';
import 'package:flutter_application_1/iot/TelaAlertas.dart';
import 'package:flutter_application_1/iot/TelaHistorico.dart';
import 'package:flutter_application_1/iot/notification_service.dart';

class TelaDados extends StatefulWidget {
  final bool administrador;

  const TelaDados({super.key, this.administrador = false});

  @override
  State<TelaDados> createState() => _TelaDadosState();
}

class _TelaDadosState extends State<TelaDados> {
  String ipAtual = '';
  List<SensorData> _dados = [];
  bool _carregando = true;
  String? _erro;
  Timer? _timer;
  Timer? _timerKeepAlive;
  int _contador = 20;
  bool _modoAutomatico = false;
  bool _bombaLigada = false;
  bool _coolerLigado = false;
  bool _temperaturaLigada = false;

  Cultivo? _cultivoAtual;
  List<Cultivo> _cultivosDisponiveis = [];
  final Map<String, DateTime> _ultimaNotificacao = {};
  final Duration _notificacaoCooldown = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _carregarIpAutomaticamente();
    _iniciarAtualizacaoAutomatica();
    _iniciarKeepAlive();
  }

  Future<void> _carregarIpAutomaticamente() async {
    final ip = await IpUtil.carregarIp();
    if (ip != null && ip.startsWith('http')) {
      final ok = await ApiService.testarConexao(ip);
      if (ok) {
        setState(() {
          ipAtual = ip;
        });
        _buscarDados();
        _buscarCultivoAtual();
        _buscarEstadoAtuadores();
      } else {
        print('❌ IP lido do arquivo não respondeu: $ip');
      }
    } else {
      print('⚠️ IP inválido ou ausente no arquivo');
    }
  }

  void _iniciarAtualizacaoAutomatica() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _contador--;
      });

      if (_contador == 0) {
        _buscarDados();
        _contador = 20;
      }
    });
  }

  void _iniciarKeepAlive() {
    // Faz ping a cada 15 minutos para manter a API acordada no Render
    _timerKeepAlive = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (ipAtual.isNotEmpty && ipAtual.startsWith('http')) {
        pingApiKeepAlive(ipAtual)
            .then((_) {
              print('✅ Keep-alive: API respondeu');
            })
            .catchError((e) {
              print('⚠️ Keep-alive falhou: $e');
            });
      }
    });
  }

  Future<void> _buscarDados() async {
    if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;
    try {
      final novosDados = await fetchDados(ipAtual);
      if (novosDados.isNotEmpty) {
        setState(() {
          _dados = novosDados;
          _carregando = false;
          _erro = null;
        });
        await _avaliarNotificacoesPreditivas();
      } else {
        throw Exception('Sem dados válidos');
      }
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _buscarCultivoAtual() async {
    if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;
    try {
      final cultivo = await fetchCultivoAtual(ipAtual);
      setState(() {
        _cultivoAtual = cultivo;
      });
    } catch (e) {
      print('Erro ao buscar cultivo atual: $e');
    }
  }

  Future<void> _buscarEstadoAtuadores() async {
    if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;
    try {
      final estado = await fetchEstadoAtuadores(ipAtual);
      if (!mounted) return;
      setState(() {
        _modoAutomatico = estado['modoAutomatico'] == true;
        _bombaLigada = estado['bombaLigada'] == true;
        _coolerLigado = estado['coolerLigado'] == true;
        _temperaturaLigada = estado['temperaturaLigada'] == true;
      });
    } catch (_) {}
  }

  void _atualizarEstadoAtuadores(Map<String, dynamic> estado) {
    if (!mounted) return;
    setState(() {
      _modoAutomatico = estado['modoAutomatico'] == true;
      _bombaLigada = estado['bombaLigada'] == true;
      _coolerLigado = estado['coolerLigado'] == true;
      _temperaturaLigada = estado['temperaturaLigada'] == true;
    });
  }

  Future<void> _alterarModoAutomatico(bool ativo) async {
    try {
      final estado = await definirModoAutomatico(ipAtual, ativo);
      _atualizarEstadoAtuadores(estado);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao alterar modo: $e')));
    }
  }

  Future<void> _buscarCultivosDisponiveis() async {
    if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;
    try {
      final lista = await fetchCultivos(ipAtual);
      setState(() {
        _cultivosDisponiveis = lista;
      });
    } catch (e) {
      print('Erro ao buscar cultivos disponíveis: $e');
    }
  }

  Future<void> _alterarCultivo(int id) async {
    if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;
    try {
      await habilitarCultivo(ipAtual, id);
      await _buscarCultivoAtual();
      await _buscarDados();
    } catch (e) {
      print('Erro ao alterar cultivo: $e');
    }
  }

  bool _podeNotificar(String chave) {
    final ultima = _ultimaNotificacao[chave];
    return ultima == null ||
        DateTime.now().difference(ultima) > _notificacaoCooldown;
  }

  void _registrarNotificacao(String chave) {
    _ultimaNotificacao[chave] = DateTime.now();
  }

  Future<void> _avaliarNotificacoesPreditivas() async {
    if (_cultivoAtual == null || _dados.isEmpty) return;

    final ultimo = _dados.last;
    if (ultimo.temperatura == null || ultimo.umidadeSolo == null) return;

    final temp = ultimo.temperatura!;
    final solo = ultimo.umidadeSolo!;
    final cultivo = _cultivoAtual!;

    const margemPercentual = 0.12;
    final tempMargin =
        (cultivo.temperaturaMaxima - cultivo.temperaturaMinima) *
        margemPercentual;
    final soloMargin =
        (cultivo.umidadeSoloMaxima - cultivo.umidadeSoloMinima) *
        margemPercentual;

    final tempProximaLimite =
        (temp - cultivo.temperaturaMinima).abs() <= tempMargin ||
        (cultivo.temperaturaMaxima - temp).abs() <= tempMargin;
    final soloProximoLimite =
        (solo - cultivo.umidadeSoloMinima).abs() <= soloMargin ||
        (cultivo.umidadeSoloMaxima - solo).abs() <= soloMargin;

    if (tempProximaLimite && _podeNotificar('TEMPERATURA')) {
      _registrarNotificacao('TEMPERATURA');
      await NotificationService.showNotification(
        id: 1,
        title: 'Temperatura em atenção',
        body:
            'A temperatura da estufa está próxima dos limites para ${cultivo.nome}. Verifique o controle térmico.',
      );
    }

    if (soloProximoLimite && _podeNotificar('SOLO')) {
      _registrarNotificacao('SOLO');
      await NotificationService.showNotification(
        id: 2,
        title: 'Umidade do solo em atenção',
        body:
            'A umidade do solo está próxima dos limites para ${cultivo.nome}. Cheque irrigação ou drenagem.',
      );
    }
  }

  Future<void> _mostrarFormularioCadastroCultivo() async {
    if (!widget.administrador) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas administradores podem cadastrar plantas.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nomeController = TextEditingController();
    final tipoController = TextEditingController();
    final temperaturaMinimaController = TextEditingController();
    final temperaturaMaximaController = TextEditingController();
    final umidadeMinimaController = TextEditingController();
    final umidadeMaximaController = TextEditingController();
    final umidadeSoloMinimaController = TextEditingController();
    final umidadeSoloMaximaController = TextEditingController();
    String? errorMessage;
    bool isSubmitting = false;
    final baseContext = context;
    bool dialogAtivo = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cadastrar nova planta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    TextField(
                      controller: tipoController,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                    TextField(
                      controller: temperaturaMinimaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Temp. mínima (°C)',
                      ),
                    ),
                    TextField(
                      controller: temperaturaMaximaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Temp. máxima (°C)',
                      ),
                    ),
                    TextField(
                      controller: umidadeMinimaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Umidade mínima (%)',
                      ),
                    ),
                    TextField(
                      controller: umidadeMaximaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Umidade máxima (%)',
                      ),
                    ),
                    TextField(
                      controller: umidadeSoloMinimaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Umidade do solo mínima (%)',
                      ),
                    ),
                    TextField(
                      controller: umidadeSoloMaximaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Umidade do solo máxima (%)',
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            final nome = nomeController.text.trim();
                            final tipo = tipoController.text.trim();
                            final temperaturaMinima = double.tryParse(
                              temperaturaMinimaController.text.replaceAll(
                                ',',
                                '.',
                              ),
                            );
                            final temperaturaMaxima = double.tryParse(
                              temperaturaMaximaController.text.replaceAll(
                                ',',
                                '.',
                              ),
                            );
                            final umidadeMinima = double.tryParse(
                              umidadeMinimaController.text.replaceAll(',', '.'),
                            );
                            final umidadeMaxima = double.tryParse(
                              umidadeMaximaController.text.replaceAll(',', '.'),
                            );
                            final umidadeSoloMinima = double.tryParse(
                              umidadeSoloMinimaController.text.replaceAll(
                                ',',
                                '.',
                              ),
                            );
                            final umidadeSoloMaxima = double.tryParse(
                              umidadeSoloMaximaController.text.replaceAll(
                                ',',
                                '.',
                              ),
                            );

                            if (nome.isEmpty || tipo.isEmpty) {
                              setState(() {
                                errorMessage = 'Nome e tipo são obrigatórios.';
                              });
                              return;
                            }

                            if ([
                              temperaturaMinima,
                              temperaturaMaxima,
                              umidadeMinima,
                              umidadeMaxima,
                              umidadeSoloMinima,
                              umidadeSoloMaxima,
                            ].contains(null)) {
                              setState(() {
                                errorMessage =
                                    'Informe valores numéricos válidos para todos os parâmetros.';
                              });
                              return;
                            }

                            setState(() {
                              isSubmitting = true;
                              errorMessage = null;
                            });

                            try {
                              await criarCultivo(ipAtual, {
                                'nome': nome,
                                'tipo': tipo,
                                'temperaturaMinima': temperaturaMinima,
                                'temperaturaMaxima': temperaturaMaxima,
                                'umidadeMinima': umidadeMinima,
                                'umidadeMaxima': umidadeMaxima,
                                'umidadeSoloMinima': umidadeSoloMinima,
                                'umidadeSoloMaxima': umidadeSoloMaxima,
                              });

                              if (!mounted) return;

                              final navigator = Navigator.of(
                                baseContext,
                                rootNavigator: true,
                              );
                              if (dialogAtivo && navigator.canPop()) {
                                dialogAtivo = false;
                                navigator.pop();
                              }

                              final messenger = ScaffoldMessenger.maybeOf(
                                baseContext,
                              );
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Planta cadastrada com sucesso.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              await _buscarCultivosDisponiveis();
                            } catch (e) {
                              if (dialogAtivo && mounted) {
                                setState(() {
                                  errorMessage =
                                      'Falha ao cadastrar planta: $e';
                                });
                              }
                            } finally {
                              if (dialogAtivo && mounted) {
                                setState(() {
                                  isSubmitting = false;
                                });
                              }
                            }
                          },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoDeIp() {
    final ipController = TextEditingController(
      text: ipAtual.isNotEmpty ? ipAtual : 'https://api-estufa.onrender.com',
    );
    String modoApi =
        ipAtual.contains('localhost') || ipAtual.contains('127.0.0.1')
            ? 'local'
            : 'hospedada';
    bool conexaoOk = false;
    String? mensagemTeste;

    String resolverUrl(String valor, String tipo) {
      var base = valor.trim();
      if (base.isEmpty) {
        return tipo == 'local'
            ? 'http://localhost:8080'
            : 'https://api-estufa.onrender.com';
      }

      if (!base.startsWith('http://') && !base.startsWith('https://')) {
        base = tipo == 'local' ? 'http://$base' : 'https://$base';
      }

      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }

      return base;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) => AlertDialog(
                title: const Text('Configurar API da estufa'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: modoApi,
                      decoration: const InputDecoration(
                        labelText: 'Origem da API',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'hospedada',
                          child: Text('Hospedada (Render)'),
                        ),
                        DropdownMenuItem(
                          value: 'local',
                          child: Text('Local (localhost)'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            modoApi = valor;
                            if (valor == 'local' && ipController.text.isEmpty) {
                              ipController.text = 'http://localhost:8080';
                            } else if (valor == 'hospedada' &&
                                ipController.text.isEmpty) {
                              ipController.text =
                                  'https://api-estufa.onrender.com';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ipController,
                      decoration: InputDecoration(
                        labelText:
                            modoApi == 'local' ? 'URL local' : 'URL hospedada',
                        hintText:
                            modoApi == 'local'
                                ? 'http://localhost:8080'
                                : 'https://api-estufa.onrender.com',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      modoApi == 'local'
                          ? 'Use essa opção quando a API estiver rodando na sua máquina.'
                          : 'Use essa opção para a API pública hospedada no Render.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (mensagemTeste != null)
                      Text(
                        mensagemTeste!,
                        style: TextStyle(
                          color: conexaoOk ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final urlTeste = resolverUrl(ipController.text, modoApi);
                      try {
                        final dados = await fetchDados(urlTeste);
                        if (dados.isNotEmpty &&
                            // ignore: unnecessary_type_check, unnecessary_null_comparison
                            dados.every(
                              // ignore: unnecessary_type_check
                              (d) => d is SensorData && d.temperatura != null,
                            )) {
                          setDialogState(() {
                            conexaoOk = true;
                            mensagemTeste = '✅ Conexão bem-sucedida!';
                          });
                        } else {
                          throw Exception('Resposta inválida');
                        }
                      } catch (e) {
                        setDialogState(() {
                          conexaoOk = false;
                          mensagemTeste = '❌ Falha na conexão';
                        });
                      }
                    },
                    child: const Text('Testar conexão'),
                  ),
                  ElevatedButton(
                    onPressed:
                        conexaoOk
                            ? () {
                              final urlFinal = resolverUrl(
                                ipController.text,
                                modoApi,
                              );
                              this.setState(() {
                                ipAtual = urlFinal;
                                _contador = 20;
                              });
                              _buscarDados();
                              _buscarCultivoAtual();
                              Navigator.pop(context);
                            }
                            : null,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Future<void> _removerCultivoConfirmado(Cultivo cultivo) async {
    if (!widget.administrador) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas administradores podem remover plantas.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Remover planta'),
            content: Text('Deseja remover "${cultivo.nome}" do sistema?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await removerCultivo(ipAtual, cultivo.id);
      await _buscarCultivosDisponiveis();
      await _buscarCultivoAtual();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Planta "${cultivo.nome}" removida com sucesso.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover planta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarMenuCultivo() async {
    if (ipAtual.isEmpty || !ipAtual.startsWith('http')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Configure o IP da API primeiro')));
      return;
    }

    await _buscarCultivoAtual();
    await _buscarCultivosDisponiveis();

    if (!mounted) {
      return;
    }

    if (_cultivoAtual == null || _cultivosDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar os cultivos')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF3FFF6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.eco_outlined, color: Color(0xFF0E7D63)),
                      SizedBox(width: 8),
                      Text(
                        'Plantas cadastradas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF0A4E44),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_cultivosDisponiveis.length} cultivos disponíveis para esta safra',
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E7D63), Color(0xFF0A4E44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_florist,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _cultivoAtual?.nome ?? 'Nenhum cultivo ativo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'ATIVA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tipo: ${_cultivoAtual?.tipo ?? '--'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Temp: ${_cultivoAtual?.temperaturaMinima}°C - ${_cultivoAtual?.temperaturaMaxima}°C',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Umidade: ${_cultivoAtual?.umidadeMinima}% - ${_cultivoAtual?.umidadeMaxima}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Selecionar outra planta',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A4E44),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (widget.administrador)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _mostrarFormularioCadastroCultivo,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Cadastrar planta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E7D63),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final removiveis =
                                  _cultivosDisponiveis
                                      .where((c) => !c.habilitada)
                                      .toList();

                              if (removiveis.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não há plantas disponíveis para remoção.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              _removerCultivoConfirmado(removiveis.first);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remover'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _cultivosDisponiveis.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cultivo = _cultivosDisponiveis[index];
                        final isAtivo = cultivo.habilitada;
                        return Material(
                          color:
                              isAtivo ? const Color(0xFFE0F7E8) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color:
                                    isAtivo
                                        ? const Color(0xFF0E7D63)
                                        : Colors.green.shade100,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  isAtivo
                                      ? const Color(0xFF0E7D63)
                                      : Colors.green.shade100,
                              child: Icon(
                                isAtivo ? Icons.check : Icons.spa_outlined,
                                color:
                                    isAtivo
                                        ? Colors.white
                                        : const Color(0xFF0E7D63),
                              ),
                            ),
                            title: Text(
                              cultivo.nome,
                              style: TextStyle(
                                fontWeight:
                                    isAtivo ? FontWeight.w700 : FontWeight.w600,
                                color: const Color(0xFF0A4E44),
                              ),
                            ),
                            subtitle: Text(cultivo.tipo),
                            trailing:
                                widget.administrador && !isAtivo
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removerCultivoConfirmado(
                                            cultivo,
                                          ),
                                    )
                                    : (isAtivo
                                        ? const Text(
                                          'Atual',
                                          style: TextStyle(
                                            color: Color(0xFF0E7D63),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                        : const Icon(Icons.swap_horiz)),
                            onTap: () async {
                              if (isAtivo) return;

                              await _alterarCultivo(cultivo.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerKeepAlive?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _dados.isNotEmpty ? _dados.last : null;
    final saude = _calcularSaude(_dados, _cultivoAtual);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IoT - Estufa'),
          backgroundColor: const Color(0xFF0E7D63),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _mostrarDialogoDeIp,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _mostrarMenuCultivo,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E7D63), Color(0xFF13A15D)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_florist,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          _cultivoAtual?.nome ?? 'Cultivo',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.sensors), text: 'Sensores'),
              Tab(icon: Icon(Icons.warning_amber), text: 'Alertas'),
              Tab(icon: Icon(Icons.show_chart), text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── ABA 1: SENSORES ──────────────────────────────────────────
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.grey.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, size: 18),
                      const SizedBox(width: 6),
                      Text('Atualizando em $_contador segundos'),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : _erro != null
                          ? Center(child: Text('Erro: $_erro'))
                          : SingleChildScrollView(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                // Score de saúde
                                _buildScoreSaude(saude),
                                const SizedBox(height: 14),
                                // Cards de leitura com gauge
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  children: [
                                    _buildGaugeCard(
                                      '🌡️ Temperatura',
                                      ultimo?.temperatura,
                                      _cultivoAtual?.temperaturaMinima,
                                      _cultivoAtual?.temperaturaMaxima,
                                      '°C',
                                      Colors.red.shade400,
                                    ),
                                    _buildGaugeCard(
                                      '💧 Umidade',
                                      ultimo?.umidade,
                                      _cultivoAtual?.umidadeMinima,
                                      _cultivoAtual?.umidadeMaxima,
                                      '%',
                                      Colors.blue.shade400,
                                    ),
                                    _buildGaugeCard(
                                      '🌱 Umid. Solo',
                                      ultimo?.umidadeSolo,
                                      _cultivoAtual?.umidadeSoloMinima,
                                      _cultivoAtual?.umidadeSoloMaxima,
                                      '%',
                                      Colors.brown.shade400,
                                    ),
                                    _buildFeatureCard(
                                      titulo: 'Aquecedor',
                                      subtitulo: 'Relé',
                                      valor:
                                          _temperaturaLigada
                                              ? 'Ligado'
                                              : 'Desligado',
                                      icone: Icons.local_fire_department,
                                      cor: Colors.orange.shade400,
                                      onTap:
                                          () => _confirmarAcaoRele(
                                            titulo: 'Aquecedor',
                                            chave: 'temperatura',
                                          ),
                                    ),
                                    _buildFeatureCard(
                                      titulo: 'Cooler',
                                      subtitulo: 'Relé',
                                      valor:
                                          _coolerLigado
                                              ? 'Ligado'
                                              : 'Desligado',
                                      icone: Icons.air,
                                      cor: Colors.lightBlue.shade400,
                                      onTap:
                                          () => _confirmarAcaoRele(
                                            titulo: 'Cooler',
                                          ),
                                    ),
                                    _buildFeatureCard(
                                      titulo: 'Bomba',
                                      subtitulo: 'Relé',
                                      valor:
                                          _bombaLigada ? 'Ligada' : 'Desligada',
                                      icone: Icons.water_drop,
                                      cor: Colors.blue.shade400,
                                      onTap:
                                          () => _confirmarAcaoRele(
                                            titulo: 'Bomba',
                                          ),
                                    ),
                                    _buildFeatureCard(
                                      titulo: 'Modo automático',
                                      subtitulo:
                                          _modoAutomatico ? 'Ativo' : 'Manual',
                                      valor:
                                          _modoAutomatico
                                              ? 'Ativo'
                                              : 'Desligado',
                                      icone: Icons.auto_mode,
                                      cor: Colors.green.shade600,
                                      onTap:
                                          () => _alterarModoAutomatico(
                                            !_modoAutomatico,
                                          ),
                                    ),
                                  ],
                                ),
                                // Últimas leituras
                                if (_dados.length > 1) ...[
                                  const SizedBox(height: 14),
                                  _buildUltimasLeituras(),
                                ],
                              ],
                            ),
                          ),
                ),
              ],
            ),
            // ── ABA 2: ALERTAS ───────────────────────────────────────────
            ipAtual.isNotEmpty
                ? TelaAlertas(ipAtual: ipAtual)
                : const Center(child: Text('Configure o IP da API primeiro')),
            // ── ABA 3: HISTÓRICO ─────────────────────────────────────────
            ipAtual.isNotEmpty
                ? TelaHistorico(ipAtual: ipAtual)
                : const Center(child: Text('Configure o IP da API primeiro')),
          ],
        ),
      ),
    );
  }

  /// Calcula % de leituras recentes dentro da faixa ideal do cultivo
  double _calcularSaude(List<SensorData> dados, Cultivo? cultivo) {
    if (cultivo == null || dados.isEmpty) return 0.0;
    final ultimas =
        dados.length > 50 ? dados.sublist(dados.length - 50) : dados;
    int ok = 0;
    for (final d in ultimas) {
      final tempOk =
          d.temperatura != null &&
          d.temperatura! >= cultivo.temperaturaMinima &&
          d.temperatura! <= cultivo.temperaturaMaxima;
      final umidOk =
          d.umidade != null &&
          d.umidade! >= cultivo.umidadeMinima &&
          d.umidade! <= cultivo.umidadeMaxima;
      final soloOk =
          d.umidadeSolo != null &&
          d.umidadeSolo! >= cultivo.umidadeSoloMinima &&
          d.umidadeSolo! <= cultivo.umidadeSoloMaxima;
      if (tempOk && umidOk && soloOk) ok++;
    }
    return ok / ultimas.length * 100;
  }

  Widget _buildScoreSaude(double saude) {
    final Color cor =
        saude >= 80
            ? const Color(0xFF0E7D63)
            : saude >= 50
            ? const Color(0xFFB54708)
            : const Color(0xFFB42318);
    final String texto =
        saude >= 80
            ? 'Ótimo'
            : saude >= 50
            ? 'Atenção'
            : 'Crítico';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: saude / 100,
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                ),
                Text(
                  '${saude.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score de Saúde',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                Text(
                  'Baseado nas últimas ${_dados.length > 50 ? 50 : _dados.length} leituras vs faixa ideal',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard(
    String titulo,
    double? valor,
    double? min,
    double? max,
    String unidade,
    Color cor,
  ) {
    final dentroFaixa =
        valor != null && min != null && max != null
            ? valor >= min && valor <= max
            : null;
    final statusCor =
        dentroFaixa == null
            ? Colors.grey
            : dentroFaixa
            ? const Color(0xFF0E7D63)
            : const Color(0xFFB42318);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text(
            valor != null ? '${valor.toStringAsFixed(1)} $unidade' : '--',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          if (min != null && max != null)
            Text(
              'Faixa: ${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} $unidade',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          if (dentroFaixa != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  dentroFaixa ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: statusCor,
                ),
                const SizedBox(width: 4),
                Text(
                  dentroFaixa ? 'Ideal' : 'Fora da faixa',
                  style: TextStyle(
                    fontSize: 11,
                    color: statusCor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String titulo,
    required String subtitulo,
    required String valor,
    required IconData icone,
    required Color cor,
    String? descricao,
    VoidCallback? onTap,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 28, color: cor),
          ),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          if (descricao != null)
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            onTap != null ? 'Toque para controlar' : 'Visual apenas',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Future<void> _confirmarAcaoRele({required String titulo, String? chave}) async {
    final duracaoMaxima = chave == 'temperatura' ? 35 : 55;
    final ativar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Ativar $titulo?'),
            content: Text(
              'O relé será ativado por no máximo $duracaoMaxima segundos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Ativar'),
              ),
            ],
          ),
    );

    if (ativar != true || !mounted) return;

    try {
      final estado = await acionarAtuadorManual(
        ipAtual,
        chave ?? titulo.toLowerCase(),
        duracaoSegundos: duracaoMaxima,
      );
      _atualizarEstadoAtuadores(estado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$titulo ativado por até $duracaoMaxima segundos.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao ativar $titulo: $e')));
    }
  }

  Widget _buildUltimasLeituras() {
    final ultimas = _dados.reversed.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              'Últimas leituras',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ...ultimas.map(
            (d) => ListTile(
              dense: true,
              leading: const Icon(
                Icons.sensors,
                size: 18,
                color: Color(0xFF0E7D63),
              ),
              title: Text(
                '${d.temperatura?.toStringAsFixed(1) ?? '--'}°C  •  '
                '${d.umidade?.toStringAsFixed(1) ?? '--'}%  •  '
                'solo ${d.umidadeSolo?.toStringAsFixed(1) ?? '--'}%',
                style: const TextStyle(fontSize: 12),
              ),
              subtitle:
                  d.significado != null
                      ? Text(
                        d.significado!,
                        style: const TextStyle(fontSize: 11),
                      )
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
