import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/iot/RelatorioDiario.dart';
import 'package:flutter_application_1/iot/api_service.dart' as iot_api;

class TelaHistorico extends StatefulWidget {
  final String ipAtual;
  const TelaHistorico({super.key, required this.ipAtual});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  List<RelatorioDiario> _dados = [];
  bool _carregando = true;
  String? _erro;
  String _periodo = 'semanal';
  bool _showTemp = true;
  bool _showUmidade = true;
  bool _showSolo = true;

  static const _verde = Color(0xFF0E7D63);
  static const _azul = Color(0xFF1570EF);
  static const _marrom = Color(0xFF7A4E2B);
  static const _vermelho = Color(0xFFD92D20);

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
      final lista = await iot_api.fetchRelatorios(widget.ipAtual, _periodo);
      setState(() {
        _dados = lista;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  void _setPeriodo(String p) {
    setState(() => _periodo = p);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFF6),
      appBar: AppBar(
        title: const Text('Histórico Consolidado'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodoSelector(),
          _buildTogglesSeries(),
          Expanded(child: _buildCorpo()),
        ],
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text(
            'Período:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          _periodoBtn('semanal', '7 dias'),
          const SizedBox(width: 8),
          _periodoBtn('mensal', '30 dias'),
        ],
      ),
    );
  }

  Widget _periodoBtn(String valor, String label) {
    final ativo = _periodo == valor;
    return GestureDetector(
      onTap: () => _setPeriodo(valor),
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

  Widget _buildTogglesSeries() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _toggle('Temp', _vermelho, _showTemp, (v) => setState(() => _showTemp = v)),
          const SizedBox(width: 10),
          _toggle('Umidade', _azul, _showUmidade, (v) => setState(() => _showUmidade = v)),
          const SizedBox(width: 10),
          _toggle('Solo', _marrom, _showSolo, (v) => setState(() => _showSolo = v)),
        ],
      ),
    );
  }

  Widget _toggle(String label, Color cor, bool ativo, ValueChanged<bool> onChange) {
    return GestureDetector(
      onTap: () => onChange(!ativo),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: ativo ? cor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ativo ? cor : Colors.grey,
              fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorpo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
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
    if (_dados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Sem dados consolidados para este período.\nAguarde o job noturno ou use "Consolidar" no desktop.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGrafico(),
          const SizedBox(height: 16),
          _buildTabela(),
        ],
      ),
    );
  }

  Widget _buildGrafico() {
    final labels = _dados.map((d) => d.labelCurto).toList();

    List<LineChartBarData> linhas = [];

    if (_showTemp) {
      linhas.add(_linha(
        _dados.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.tempMedia))
            .toList(),
        _vermelho,
        'Temp',
      ));
    }
    if (_showUmidade) {
      linhas.add(_linha(
        _dados.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.umidadeMedia))
            .toList(),
        _azul,
        'Umidade',
      ));
    }
    if (_showSolo) {
      linhas.add(_linha(
        _dados.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.soloMedia))
            .toList(),
        _marrom,
        'Solo',
      ));
    }

    return Container(
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
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 16),
      height: 280,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, meta) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _dados.length > 10
                    ? (_dados.length / 5).floorToDouble()
                    : 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i >= 0 && i < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[i],
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          lineBarsData: linhas,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        s.y.toStringAsFixed(1),
                        const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _linha(List<FlSpot> spots, Color cor, String nome) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: cor,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 3, color: cor),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: cor.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildTabela() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Detalhes por dia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 44,
              columnSpacing: 16,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF0E7D63),
              ),
              dataTextStyle: const TextStyle(fontSize: 12),
              columns: const [
                DataColumn(label: Text('Data')),
                DataColumn(label: Text('Temp\nméd'), numeric: true),
                DataColumn(label: Text('Temp\nmin'), numeric: true),
                DataColumn(label: Text('Temp\nmax'), numeric: true),
                DataColumn(label: Text('Umid\nméd'), numeric: true),
                DataColumn(label: Text('Solo\nméd'), numeric: true),
                DataColumn(label: Text('Leituras'), numeric: true),
              ],
              rows: _dados.map((d) => DataRow(cells: [
                DataCell(Text(d.labelCurto)),
                DataCell(Text(d.tempMedia.toStringAsFixed(1))),
                DataCell(Text(d.tempMinima.toStringAsFixed(1))),
                DataCell(Text(d.tempMaxima.toStringAsFixed(1))),
                DataCell(Text(d.umidadeMedia.toStringAsFixed(1))),
                DataCell(Text(d.soloMedia.toStringAsFixed(1))),
                DataCell(Text(d.totalLeituras.toString())),
              ])).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
