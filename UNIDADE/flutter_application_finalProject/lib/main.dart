import 'package:flutter/material.dart';
import 'package:flutter_application_1/Perfil/perfil_page.dart';
import 'package:flutter_application_1/iot/TelaDados.dart';
import 'package:flutter_application_1/cadastro/telaInicial.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: Telainicial()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class _EcoPalette {
  static const Color mint = Color(0xFF7EDBA1);
  static const Color deep = Color(0xFF0E7D63);
  static const Color dark = Color(0xFF0A4E44);
  static const Color light = Color(0xFFF2FFF6);
  static const Color text = Color(0xFF113128);
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
  final bool hasAlert;

  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.builder,
    this.hasAlert = false,
  });
}

class HomePage extends StatefulWidget {
  final String cpfLogado;
  final bool administrador;
  final int pendenciasAprovacao;
  final int initialIndex;

  const HomePage({
    super.key,
    this.cpfLogado = '',
    this.administrador = false,
    this.pendenciasAprovacao = 0,
    this.initialIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _pendenciasAprovacao;
  int _selectedIndex = 0;
  int _previousIndex = 0;
  late List<_MenuEntry> _entries;

  @override
  void initState() {
    super.initState();
    _pendenciasAprovacao = widget.pendenciasAprovacao;
    _entries = _buildEntries();
    _selectedIndex = widget.initialIndex.clamp(0, _entries.length - 1);
  }

  void _atualizarPendencias(int quantidade) {
    setState(() {
      _pendenciasAprovacao = quantidade;
      _entries = _buildEntries();
    });
  }

  void _navigateTo(int index) {
    final oldIndex = _selectedIndex;
    setState(() {
      _previousIndex = oldIndex;
      _selectedIndex = index;
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _sairParaAreaTrabalho() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sair da conta'),
            content: const Text('Deseja voltar para a tela inicial?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    if (confirmar != true || !mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Telainicial()),
      (_) => false,
    );
  }

  List<_MenuEntry> _buildEntries() {
    return [
      _MenuEntry(
        icon: Icons.sensors_outlined,
        label: 'IoT',
        builder: (_) => TelaDados(administrador: widget.administrador),
      ),
      _MenuEntry(
        icon: Icons.person_outline,
        label: 'Perfil',
        hasAlert: widget.administrador && _pendenciasAprovacao > 0,
        builder:
            (_) => PerfilPage(
              cpfLogado: widget.cpfLogado,
              administrador: widget.administrador,
              onPendenciasAtualizadas: _atualizarPendencias,
            ),
      ),
      _MenuEntry(
        icon: Icons.computer_outlined,
        label: 'MSW',
        builder: (_) => const MonitorSerialWebPage(),
      ),
    ];
  }

  Widget _buildWaveBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8FFF0), Color(0xFFC6F3D6)],
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: _EcoPalette.mint.withValues(alpha: 0.24),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -90,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: _EcoPalette.deep.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 150,
            child: CustomPaint(painter: _WavePainter()),
          ),
        ),
      ],
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      backgroundColor: _EcoPalette.light,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_EcoPalette.deep, _EcoPalette.dark],
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/imagesC/logo.png'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estufa Smart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Menu de navegacao',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemBuilder: (context, index) {
                final item = _entries[index];
                final selected = index == _selectedIndex;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color:
                      selected
                          ? _EcoPalette.mint.withValues(alpha: 0.26)
                          : Colors.white,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.icon,
                          color: selected ? _EcoPalette.dark : _EcoPalette.deep,
                        ),
                        if (item.hasAlert)
                          const Positioned(
                            right: -2,
                            top: -2,
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: _EcoPalette.text,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () => _navigateTo(index),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text(
                    'Sair',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Voltar para a area de trabalho'),
                  onTap: _sairParaAreaTrabalho,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEntry = _entries[_selectedIndex];
    return Scaffold(
      backgroundColor: _EcoPalette.light,
      endDrawer: _buildAppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _EcoPalette.text,
        title: Text(
          currentEntry.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          _buildWaveBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.74),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x200A4E44),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.energy_savings_leaf,
                          color: _EcoPalette.deep,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.administrador
                                ? 'Modo administrador ativo'
                                : 'Navegacao inteligente ativa',
                            style: const TextStyle(
                              color: _EcoPalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.administrador)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _pendenciasAprovacao > 0
                                      ? Colors.red.shade100
                                      : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Pendencias: $_pendenciasAprovacao',
                              style: TextStyle(
                                color:
                                    _pendenciasAprovacao > 0
                                        ? Colors.red.shade900
                                        : Colors.green.shade900,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.88),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final movingForward =
                                _selectedIndex >= _previousIndex;
                            final begin =
                                movingForward
                                    ? const Offset(0.08, 0)
                                    : const Offset(-0.08, 0);
                            final offsetAnimation = Tween<Offset>(
                              begin: begin,
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(_selectedIndex),
                            child: currentEntry.builder(context),
                          ),
                        ),
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

class MonitorSerialWebPage extends StatelessWidget {
  const MonitorSerialWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.computer_outlined,
                  size: 56,
                  color: _EcoPalette.deep,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Monitor Serial Web',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _EcoPalette.text,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esta funcionalidade ainda não está disponível.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: _EcoPalette.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final first =
        Path()
          ..moveTo(0, size.height * 0.55)
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.28,
            size.width * 0.52,
            size.height * 0.52,
          )
          ..quadraticBezierTo(
            size.width * 0.82,
            size.height * 0.78,
            size.width,
            size.height * 0.42,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    paint.color = _EcoPalette.deep.withValues(alpha: 0.28);
    canvas.drawPath(first, paint);

    final second =
        Path()
          ..moveTo(0, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.94,
            size.width * 0.55,
            size.height * 0.66,
          )
          ..quadraticBezierTo(
            size.width * 0.85,
            size.height * 0.38,
            size.width,
            size.height * 0.64,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    paint.color = _EcoPalette.dark.withValues(alpha: 0.34);
    canvas.drawPath(second, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GuiaCultivoPage extends StatelessWidget {
  const GuiaCultivoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF1),
      appBar: AppBar(
        title: const Text('Guia de cultivo'),
        backgroundColor: const Color(0xFF0E7D63),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              title: 'Como usar sua estufa',
              text:
                  'Use a estufa para manter temperatura e umidade estáveis, proteger contra pragas e prolongar o ciclo de cultivo.',
              icon: Icons.thermostat_auto,
            ),
            const SizedBox(height: 14),
            _buildCard(
              title: 'Parâmetros recomendados',
              text:
                  'Temperatura ideal: 20-28°C. Umidade do ar: 60-80%. Umidade do solo: 40-70%. Ajuste conforme o cultivo.',
              icon: Icons.water_drop,
            ),
            const SizedBox(height: 14),
            _buildCard(
              title: 'Boas práticas',
              text:
                  'Faça rotação de cultivos, posicione a estufa em local com luz adequada e verifique ventilação diária.',
              icon: Icons.eco,
            ),
            const SizedBox(height: 14),
            _buildCard(
              title: 'Use os dados do app',
              text:
                  'Acesse a aba IoT para ver leituras em tempo real e use o perfil para acompanhar histórico e alertas.',
              icon: Icons.insights,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String text,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0E7D63).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0E7D63)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E7D63),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
