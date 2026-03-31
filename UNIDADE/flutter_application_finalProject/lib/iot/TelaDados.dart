import 'dart:async';
import 'package:flutter_application_1/cadastro/api_service.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/iot/api_service.dart';
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/Cultivo.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Dados do Sensor'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
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
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, size: 20),
                SizedBox(width: 8),
                Text('Atualizando em $_contador segundos'),
              ],
            ),
          ),
          Expanded(
            child:
                _carregando
                    ? Center(child: CircularProgressIndicator())
                    : _erro != null
                    ? Center(child: Text('Erro: $_erro'))
                    : GridView.count(
                      crossAxisCount: 2,
                      padding: EdgeInsets.all(16),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildCard(
                          '🌡️ Temperatura',
                          '${ultimo?.temperatura ?? '--'} °C',
                        ),
                        _buildCard(
                          '💧 Umidade',
                          '${ultimo?.umidade ?? '--'} %',
                        ),
                        _buildCard(
                          '🌱 Solo',
                          '${ultimo?.umidadeSolo ?? '--'} %',
                        ),
                        _buildCardComCor(
                          ultimo?.significado ?? '...',
                          _corDoSignificado(ultimo?.significado),
                        ),
                        _buildCard('🔲 Placeholder 3', '...'),
                        _buildCard('🔲 Placeholder 4', '...'),
                      ],
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
