import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/iot/Alerta.dart';
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/api_service.dart' as iot_api;
import 'package:flutter_application_1/iot/estufa_inteligencia.dart';

class TelaAlertas extends StatefulWidget {
  final String ipAtual;
  const TelaAlertas({super.key, required this.ipAtual});

  @override
  State<TelaAlertas> createState() => _TelaAlertasState();
}

class _TelaAlertasState extends State<TelaAlertas> {
  List<Alerta> _alertas = [];
  List<SensorData> _dados = [];
  bool _carregando = true;
  String? _erro;
  String _filtro = 'todos'; // todos | CRITICO | ATENCAO
  CenarioEstufa _cenario = CenarioEstufa.padrao;

  static const _verde = Color(0xFF0E7D63);
  static const _vermelho = Color(0xFFB42318);
  static const _laranja = Color(0xFFB54708);
  static const _cinzaFundo = Color(0xFFF2FFF6);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait([
        iot_api.fetchAlertas(widget.ipAtual),
        iot_api.fetchDados(widget.ipAtual),
      ]);

      final listaApi = resultados[0] as List<Alerta>;
      final dados = resultados[1] as List<SensorData>;
      final alertasInteligentes = gerarAlertasInteligentes(dados, _cenario);
      final combinados = [...listaApi, ...alertasInteligentes];

      setState(() {
        _alertas = _removerDuplicados(combinados);
        _dados = dados;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  List<Alerta> get _alertasFiltrados {
    if (_filtro == 'todos') return _alertas;
    return _alertas
        .where((a) => a.severidade.toUpperCase() == _filtro)
        .toList();
  }

  int get _totalCriticos => _alertas.where((a) => a.isCritico).length;
  int get _totalAtencao => _alertas.where((a) => !a.isCritico).length;
  ResumoEstufa get _resumo => analisarEstufa(_dados, _cenario);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: AppBar(
        title: const Text('Alertas & IA'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          _buildResumo(),
          _buildSelecionarCenario(),
          _buildFiltros(),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    final resumo = _resumo;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resumo inteligente da estufa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Chip(
                label: Text(resumo.status),
                backgroundColor:
                    resumo.status == 'Crítico'
                        ? const Color(0xFFFEF3F2)
                        : resumo.status == 'Atenção'
                        ? const Color(0xFFFFFAEB)
                        : const Color(0xFFE6F8F1),
                labelStyle: TextStyle(
                  color:
                      resumo.status == 'Crítico'
                          ? _vermelho
                          : resumo.status == 'Atenção'
                          ? _laranja
                          : _verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(
                'Total',
                _alertas.length.toString(),
                const Color(0xFF475467),
                const Color(0xFFF2F4F7),
              ),
              _chip(
                'Críticos',
                _totalCriticos.toString(),
                _vermelho,
                const Color(0xFFFEF3F2),
              ),
              _chip(
                'Atenção',
                _totalAtencao.toString(),
                _laranja,
                const Color(0xFFFFFAEB),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricCard(
                'Temp. média',
                '${resumo.mediaTemperatura.toStringAsFixed(1)}°C',
                Icons.thermostat_outlined,
              ),
              _metricCard(
                'Umidade',
                '${resumo.mediaUmidade.toStringAsFixed(1)}%',
                Icons.water_drop_outlined,
              ),
              _metricCard(
                'Solo',
                '${resumo.mediaUmidadeSolo.toStringAsFixed(1)}%',
                Icons.grass,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: _verde, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${resumo.previsaoTemperatura} ${resumo.previsaoUmidade}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String valor, IconData icon) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _verde, size: 18),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSelecionarCenario() {
    final cenarios = [
      CenarioEstufa.padrao,
      CenarioEstufa.verao,
      CenarioEstufa.inverno,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cenário de cultivo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                cenarios.map((cenario) {
                  final ativo = _cenario.nome == cenario.nome;
                  return ChoiceChip(
                    label: Text(cenario.nome),
                    selected: ativo,
                    selectedColor: _verde.withValues(alpha: 0.16),
                    onSelected: (_) {
                      setState(() => _cenario = cenario);
                      _carregar();
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String valor, Color cor, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: cor)),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filtroBtn('todos', 'Todos'),
            const SizedBox(width: 8),
            _filtroBtn('CRITICO', 'Crítico'),
            const SizedBox(width: 8),
            _filtroBtn('ATENCAO', 'Atenção'),
          ],
        ),
      ),
    );
  }

  Widget _filtroBtn(String valor, String label) {
    final ativo = _filtro == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtro = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: ativo ? _verde : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.grey.shade700,
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Erro: $_erro', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final lista = _alertasFiltrados;
    if (lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Color(0xFF0E7D63),
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum alerta encontrado',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildCard(lista[i]),
      ),
    );
  }

  Widget _buildCard(Alerta alerta) {
    final cor = alerta.isCritico ? _vermelho : _laranja;
    final bgCor =
        alerta.isCritico ? const Color(0xFFFEF3F2) : const Color(0xFFFFFAEB);
    final icone = _iconeParaTipo(alerta.tipo);

    return Container(
      decoration: BoxDecoration(
        color: bgCor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.35), width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alerta.severidade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alerta.tipo,
                      style: TextStyle(
                        color: cor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alerta.mensagem ??
                      '${alerta.tipo}: ${alerta.valor.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Faixa: ${alerta.limiteMin.toStringAsFixed(1)} – ${alerta.limiteMax.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (alerta.geradoEm != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatarData(alerta.geradoEm!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconeParaTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TEMPERATURA':
        return Icons.thermostat;
      case 'UMIDADE':
        return Icons.water_drop;
      case 'SOLO':
        return Icons.grass;
      default:
        return Icons.warning_amber;
    }
  }

  String _formatarData(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length > 16 ? iso.substring(0, 16) : iso;
    }
  }

  List<Alerta> _removerDuplicados(List<Alerta> alertas) {
    final mapa = <String, Alerta>{};
    for (final alerta in alertas) {
      final chave =
          '${alerta.tipo.toUpperCase()}::${alerta.severidade.toUpperCase()}::${alerta.mensagem ?? alerta.valor.toString()}';
      mapa.putIfAbsent(chave, () => alerta);
    }
    return mapa.values.toList();
  }
}
