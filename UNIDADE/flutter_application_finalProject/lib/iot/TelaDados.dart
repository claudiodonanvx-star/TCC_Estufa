import 'dart:async';
import 'package:flutter_application_1/cadastro/api_service.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/iot/api_service.dart';
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/Cultivo.dart';
import 'package:flutter_application_1/iot/TelaAlertas.dart';
import 'package:flutter_application_1/iot/TelaHistorico.dart';

class TelaDados extends StatefulWidget {
  const TelaDados({super.key});

  @override
  State<TelaDados> createState() => _TelaDadosState();
}

class _TelaDadosState extends State<TelaDados> {
  String ipAtual = '';
  List<SensorData> _dados = [];
  bool _carregando = true;
  String? _erro;
  Timer? _timer;
  int _contador = 20;

  Cultivo? _cultivoAtual;
  List<Cultivo> _cultivosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _carregarIpAutomaticamente();
    _iniciarAtualizacaoAutomatica();
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

  void _mostrarDialogoDeIp() {
    final ipController = TextEditingController(text: ipAtual);
    bool conexaoOk = false;
    String? mensagemTeste;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('Configurar IP da API'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ipController,
                      decoration: InputDecoration(
                        hintText: 'https://seuip.ngrok-free.app',
                      ),
                    ),
                    SizedBox(height: 12),
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
                    child: Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final ipTeste = ipController.text.trim();
                      try {
                        final dados = await fetchDados(ipTeste);
                        if (dados.isNotEmpty &&
                            // ignore: unnecessary_type_check, unnecessary_null_comparison
                            dados.every(
                              // ignore: unnecessary_type_check
                              (d) => d is SensorData && d.temperatura != null,
                            )) {
                          setState(() {
                            conexaoOk = true;
                            mensagemTeste = '✅ Conexão bem-sucedida!';
                          });
                        } else {
                          throw Exception('Resposta inválida');
                        }
                      } catch (e) {
                        setState(() {
                          conexaoOk = false;
                          mensagemTeste = '❌ Falha na conexão';
                        });
                      }
                    },
                    child: Text('Testar conexão'),
                  ),
                  ElevatedButton(
                    onPressed:
                        conexaoOk
                            ? () {
                              setState(() {
                                ipAtual = ipController.text.trim();
                                _contador = 20;
                              });
                              _buscarDados();
                              _buscarCultivoAtual();
                              Navigator.pop(context);
                            }
                            : null,
                    child: Text('Salvar'),
                  ),
                ],
              ),
        );
      },
    );
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
                                isAtivo
                                    ? const Text(
                                      'Atual',
                                      style: TextStyle(
                                        color: Color(0xFF0E7D63),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                    : const Icon(Icons.swap_horiz),
                            onTap:
                                isAtivo
                                    ? null
                                    : () async {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_florist,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          _cultivoAtual?.nome ?? 'Cultivo',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more,
                          size: 18, color: Colors.white),
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
                      horizontal: 12, vertical: 8),
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
                  child: _carregando
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                      _buildCardComCor(
                                        ultimo?.significado ?? '...',
                                        _corDoSignificado(
                                            ultimo?.significado),
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
                : const Center(
                    child: Text('Configure o IP da API primeiro'),
                  ),
            // ── ABA 3: HISTÓRICO ─────────────────────────────────────────
            ipAtual.isNotEmpty
                ? TelaHistorico(ipAtual: ipAtual)
                : const Center(
                    child: Text('Configure o IP da API primeiro'),
                  ),
          ],
        ),
      ),
    );
  }

  /// Calcula % de leituras recentes dentro da faixa ideal do cultivo
  double _calcularSaude(List<SensorData> dados, Cultivo? cultivo) {
    if (cultivo == null || dados.isEmpty) return 0.0;
    final ultimas = dados.length > 50 ? dados.sublist(dados.length - 50) : dados;
    int ok = 0;
    for (final d in ultimas) {
      final tempOk = d.temperatura != null &&
          d.temperatura! >= cultivo.temperaturaMinima &&
          d.temperatura! <= cultivo.temperaturaMaxima;
      final umidOk = d.umidade != null &&
          d.umidade! >= cultivo.umidadeMinima &&
          d.umidade! <= cultivo.umidadeMaxima;
      final soloOk = d.umidadeSolo != null &&
          d.umidadeSolo! >= cultivo.umidadeSoloMinima &&
          d.umidadeSolo! <= cultivo.umidadeSoloMaxima;
      if (tempOk && umidOk && soloOk) ok++;
    }
    return ok / ultimas.length * 100;
  }

  Widget _buildScoreSaude(double saude) {
    final Color cor = saude >= 80
        ? const Color(0xFF0E7D63)
        : saude >= 50
            ? const Color(0xFFB54708)
            : const Color(0xFFB42318);
    final String texto = saude >= 80
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
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
    final dentroFaixa = valor != null && min != null && max != null
        ? valor >= min && valor <= max
        : null;
    final statusCor = dentroFaixa == null
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
              leading: const Icon(Icons.sensors, size: 18,
                  color: Color(0xFF0E7D63)),
              title: Text(
                '${d.temperatura?.toStringAsFixed(1) ?? '--'}°C  •  '
                '${d.umidade?.toStringAsFixed(1) ?? '--'}%  •  '
                'solo ${d.umidadeSolo?.toStringAsFixed(1) ?? '--'}%',
                style: const TextStyle(fontSize: 12),
              ),
              subtitle: d.significado != null
                  ? Text(d.significado!, style: const TextStyle(fontSize: 11))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardComCor(String titulo, Color cor) {
    return Container(
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          titulo,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _corDoSignificado(String? significado) {
    switch (significado) {
      case 'Ambiente seco e frio':
        return Colors.blue.shade300;
      case 'Ambiente ideal':
        return Colors.green.shade300;
      case 'Ambiente quente e úmido':
        return Colors.red.shade300;
      case 'Quente e seco':
        return Colors.orange.shade300;
      case 'Frio e úmido':
        return Colors.purple.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildCard(String titulo, String valor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
