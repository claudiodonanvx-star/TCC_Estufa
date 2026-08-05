import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UnidadeMonitorPage extends StatefulWidget {
  const UnidadeMonitorPage({super.key});

  @override
  State<UnidadeMonitorPage> createState() => _UnidadeMonitorPageState();
}

class _UnidadeMonitorPageState extends State<UnidadeMonitorPage> {
  final TextEditingController _deviceController = TextEditingController(
    text: '192.168.0.108',
  );
  bool _isConnecting = false;
  bool _isConnected = false;
  String _statusMessage = 'Aguardando conexão com o ESP';

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Unidade Smart',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E7D63),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Conecte o monitor da unidade ao seu ESP e abra o site diretamente.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF295045),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7EDBA1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.device_hub_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOpenSiteButton(context),
              const SizedBox(height: 14),
              _buildConnectionPanel(),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusPanel(),
                      const SizedBox(height: 18),
                      _buildAreaPanel(
                        title: 'Monitor Serial',
                        description:
                            'Acompanhe o fluxo de dados físicos, integridade da porta serial e comportamento dos sensores.',
                        highlight:
                            'Temperatura, umidade do ar, solo e comunicação.',
                        color: const Color(0xFF7EDBA1),
                      ),
                      const SizedBox(height: 18),
                      _buildAreaPanel(
                        title: 'Logs da API',
                        description:
                            'Veja os registros de backend, tempos de resposta, erros e a saúde dos endpoints.',
                        highlight: 'Ping, alertas, falhas e desempenho.',
                        color: const Color(0xFF4B8BC7),
                      ),
                      const SizedBox(height: 18),
                      _buildTwinGrid(),
                      const SizedBox(height: 18),
                      _buildCallout(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectToDevice() async {
    final rawValue = _deviceController.text.trim();
    if (rawValue.isEmpty) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Informe o IP ou URL do ESP.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Conectando ao dispositivo...';
    });

    final address =
        rawValue.startsWith('http://') || rawValue.startsWith('https://')
            ? rawValue
            : 'http://$rawValue';
    final baseUri = Uri.parse(address);
    final endpoints = <String>['/health', '/status', '/'];

    try {
      for (final endpoint in endpoints) {
        final response = await http
            .get(baseUri.resolve(endpoint))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (!mounted) return;
          setState(() {
            _isConnecting = false;
            _isConnected = true;
            _statusMessage = 'Conectado em ${baseUri.host}';
          });
          return;
        }
      }
    } catch (_) {
      // fallback below
    }

    if (!mounted) return;
    setState(() {
      _isConnecting = false;
      _isConnected = false;
      _statusMessage =
          'Não foi possível conectar. Verifique o IP ou URL do ESP.';
    });
  }

  Future<void> _transferMonitorData() async {
    if (!_isConnected) {
      setState(() {
        _statusMessage =
            'Conecte primeiro o dispositivo antes de transferir os dados.';
      });
      return;
    }

    final rawValue = _deviceController.text.trim();
    final address =
        rawValue.startsWith('http://') || rawValue.startsWith('https://')
            ? rawValue
            : 'http://$rawValue';
    final endpoint = Uri.parse('$address/monitor');

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Transferindo dados do monitor...';
    });

    try {
      final response = await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'source': 'flutter_app',
              'type': 'monitor',
              'timestamp': DateTime.now().toIso8601String(),
              'status': 'online',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Dados transferidos com sucesso para o ESP.';
        });
      } else {
        setState(() {
          _isConnecting = false;
          _statusMessage =
              'Falha ao transferir os dados. Verifique o endpoint do ESP.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Erro de rede ao transferir os dados.';
      });
    }
  }

  Widget _buildConnectionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conexão com o ESP',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _deviceController,
            decoration: const InputDecoration(
              labelText: 'IP ou URL do dispositivo',
              hintText: 'ex.: 192.168.0.108',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.wifi_tethering),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _connectToDevice,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(_isConnecting ? 'Conectando...' : 'Emparelhar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7D63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isConnecting || !_isConnected
                          ? null
                          : _transferMonitorData,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Transferir dados'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _statusMessage,
            style: TextStyle(
              color:
                  _isConnected
                      ? const Color(0xFF0E7D63)
                      : const Color(0xFF5C6B73),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenSiteButton(BuildContext context) {
    final uri = Uri.parse('https://api-estufa.onrender.com');

    return ElevatedButton.icon(
      onPressed: () async {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o site da unidade.'),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0E7D63),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.open_in_new, size: 20),
      label: const Text(
        'Abrir site da unidade',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saúde da Unidade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0E7D63),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip('Status', 'OK'),
              _buildStatusChip('SLA', '98,7%'),
              _buildStatusChip('Latency', '120ms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE9FFF1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF4B8BC7).withOpacity(0.86),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E7D63),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaPanel({
    required String title,
    required String description,
    required String highlight,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 14, height: 1.65)),
          const SizedBox(height: 14),
          Text(
            highlight,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E7D63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwinGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visão dupla',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E7D63),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: [
            _buildTwinCard(
              'Problemas',
              'Detecte falhas de conexão e sensores com leituras inconsistentes.',
              Icons.warning_amber,
              const Color(0xFFFFD166),
            ),
            _buildTwinCard(
              'Normalidade',
              'Compare os dados atuais com os padrões esperados de operação.',
              Icons.check_circle_outline,
              const Color(0xFF47D18D),
            ),
            _buildTwinCard(
              'Tendência',
              'Preveja possíveis instabilidades antes que elas se tornem críticas.',
              Icons.trending_up,
              const Color(0xFF4B8BC7),
            ),
            _buildTwinCard(
              'Ações',
              'Sugestões inteligentes para manutenção preventiva e correções rápidas.',
              Icons.bolt,
              const Color(0xFF7EDBA1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTwinCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: Color(0xFF4E636B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallout() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E7D63),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Text(
        'Este espaço é a central de monitoramento da unidade. Aqui você terá uma visão consolidada do comportamento físico (serial) e das condições de backend (API), com foco em problemas reais e tendências de falha.',
        style: TextStyle(color: Colors.white, fontSize: 14.4, height: 1.7),
      ),
    );
  }
}
