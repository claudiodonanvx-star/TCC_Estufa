import 'package:flutter/material.dart';
import 'package:flutter_application_1/cadastro/api_service.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:flutter_application_1/main.dart';

import 'cliente.dart';

void main() {
  runApp(MaterialApp(home: Telainicial(), debugShowCheckedModeBanner: false));
}

class _P {
  static const mint = Color(0xFF7EDBA1);
  static const deep = Color(0xFF0E7D63);
  static const dark = Color(0xFF0A4E44);
  static const light = Color(0xFFF2FFF6);
  static const text = Color(0xFF113128);
  static const accent = Color(0xFFB7F18C);
}

PageRouteBuilder<T> _ecoRoute<T>(Widget page, {Offset? beginOffset}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 560),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slide = Tween<Offset>(
        begin: beginOffset ?? const Offset(0.16, 0),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

InputDecoration _ecoInput(String label, IconData icon, {Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _P.text),
    prefixIcon: Icon(icon, color: _P.deep),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _P.mint.withValues(alpha: 0.85)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _P.deep, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}

class _EcoScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;

  const _EcoScaffold({this.appBar, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.light,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE9FFF1), Color(0xFFC7F3D8)],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -60,
            child: _Orb(size: 270, color: _P.mint.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: 180,
            left: -80,
            child: _Orb(size: 180, color: _P.deep.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              child: CustomPaint(painter: _WavePainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = _P.deep.withValues(alpha: 0.25);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.48)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.12,
          size.width * 0.56,
          size.height * 0.46,
        )
        ..quadraticBezierTo(
          size.width * 0.84,
          size.height * 0.82,
          size.width,
          size.height * 0.38,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );

    paint.color = _P.accent.withValues(alpha: 0.38);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.72)
        ..quadraticBezierTo(
          size.width * 0.24,
          size.height,
          size.width * 0.58,
          size.height * 0.62,
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.34,
          size.width,
          size.height * 0.62,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _EcoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onTap;
  final double? width;

  const _EcoButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
    this.width,
  });

  @override
  State<_EcoButton> createState() => _EcoButtonState();
}

class _EcoButtonState extends State<_EcoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, child) =>
                Transform.scale(scale: 1 - _controller.value, child: child),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient:
                widget.filled
                    ? const LinearGradient(colors: [_P.deep, _P.dark])
                    : null,
            color: widget.filled ? null : Colors.transparent,
            border: Border.all(
              color: widget.filled ? Colors.transparent : _P.deep,
              width: 2,
            ),
            boxShadow:
                widget.filled
                    ? [
                      BoxShadow(
                        color: _P.deep.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.filled ? Colors.white : _P.dark,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.filled ? Colors.white : _P.dark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: _P.dark.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: child,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _P.dark.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_P.deep, _P.dark]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MiniIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

// ── Logo animada: cresce na entrada e balança como planta ──────────────────
class _AnimatedPlantLogo extends StatefulWidget {
  final double size;
  const _AnimatedPlantLogo({this.size = 52});

  @override
  State<_AnimatedPlantLogo> createState() => _AnimatedPlantLogoState();
}

class _AnimatedPlantLogoState extends State<_AnimatedPlantLogo>
    with TickerProviderStateMixin {
  late final AnimationController _growController;
  late final AnimationController _swayController;
  late final AnimationController _breatheController;

  late final Animation<double> _growScale;
  late final Animation<double> _growFade;
  late final Animation<double> _sway;
  late final Animation<double> _breathe;

  @override
  void initState() {
    super.initState();

    // Crescimento na entrada
    _growController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _growScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _growController, curve: Curves.elasticOut),
    );
    _growFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _growController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Balanço contínuo (esquerda/direita como planta ao vento)
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _sway = Tween<double>(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    // Respiração sutil (pulso de escala)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _breathe = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _growController.forward();
  }

  @override
  void dispose() {
    _growController.dispose();
    _swayController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _growFade,
      child: ScaleTransition(
        scale: _growScale,
        child: AnimatedBuilder(
          animation: Listenable.merge([_swayController, _breatheController]),
          builder: (context, child) {
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..rotateZ(_sway.value)
                ..scale(_breathe.value),
              child: child,
            );
          },
          child: Image.asset(
            'assets/imagesE/logo_colorido.png',
            width: widget.size,
            height: widget.size,
          ),
        ),
      ),
    );
  }
}

class Telainicial extends StatefulWidget {

  @override
  State<Telainicial> createState() => _TelainicialState();
}

class _TelainicialState extends State<Telainicial>
    with SingleTickerProviderStateMixin {
  final TextEditingController _duvidaRapidaController = TextEditingController();

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _copyFade;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.48, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.35, curve: Curves.easeIn),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.62, curve: Curves.easeIn),
      ),
    );
    _copyFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.78, curve: Curves.easeIn),
      ),
    );
    _buttonScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 1, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _duvidaRapidaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _enviarDuvidaRapida() {
    final mensagem = _duvidaRapidaController.text.trim();
    if (mensagem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite sua dúvida antes de enviar.')),
      );
      return;
    }

    _duvidaRapidaController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dúvida enviada para o atendimento!')),
    );
  }

  void _abrirSuporte() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(Icons.support_agent, color: _P.deep),
                SizedBox(width: 8),
                Text('Atendimento ao Cliente'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.88,
              height: MediaQuery.of(context).size.height * 0.58,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _supportBox('E-mails', const [
                      'suporte@estufasmart.com',
                      'contato@estufasmart.com',
                      'sac@estufasmart.com',
                      'financeiro@estufasmart.com',
                    ]),
                    const SizedBox(height: 16),
                    _supportBox('Telefones', const [
                      '(11) 4002-8922',
                      '(19) 99999-1234',
                    ]),
                    const SizedBox(height: 16),
                    const Text(
                      'Deixe sua duvida:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escreva sua duvida aqui...',
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
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Duvida enviada!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite a duvida antes de enviar.'),
                      ),
                    );
                  }
                },
                child: const Text('Enviar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Widget _supportBox(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _P.light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContactPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atendimento rápido',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.phone, size: 17, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '(11) 4002-8922 • (19) 99999-1234',
                  style: TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Row(
            children: [
              Icon(Icons.mail, size: 17, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'suporte@estufasmart.com',
                  style: TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _duvidaRapidaController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Digite sua dúvida...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.white, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _enviarDuvidaRapida,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Enviar dúvida'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return ScaleTransition(
      scale: _buttonScale,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, _ecoRoute(LoginScreen())),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Entrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _P.dark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, _ecoRoute(CadastroClientes())),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Criar conta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
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
    return _EcoScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atendimento',
            onPressed: _abrirSuporte,
            icon: const Icon(Icons.support_agent, color: _P.dark),
          ),
          const SizedBox(width: 6),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;
            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Container(
                      height: constraints.maxHeight - 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: _P.dark.withValues(alpha: 0.20),
                            blurRadius: 38,
                            offset: const Offset(0, 22),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 48,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFD8F4E3), Color(0xFFBFE9D2)],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(36, 28, 28, 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FadeTransition(
                                        opacity: _logoFade,
                                        child: Row(
                                          children: [
                                            Hero(
                                              tag: 'auth-logo',
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.70),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const _AnimatedPlantLogo(size: 42),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'EstufaSmart',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                color: _P.dark,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Center(
                                        child: FadeTransition(
                                          opacity: _logoFade,
                                          child: ScaleTransition(
                                            scale: _logoScale,
                                            child: Image.asset(
                                              'assets/imagesE/estu.png',
                                              height: 290,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FadeTransition(
                                        opacity: _titleFade,
                                        child: const Text(
                                          'W E L C O M E',
                                          style: TextStyle(
                                            color: _P.deep,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 52,
                              child: ClipPath(
                                clipper: _RightPanelClipper(),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF197A66), Color(0xFF0E5B4C)],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(52, 34, 42, 34),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FadeTransition(
                                          opacity: _titleFade,
                                          child: const Text(
                                            'Olá!\nQue bom ver você aqui :)',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              height: 1.14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        FadeTransition(
                                          opacity: _copyFade,
                                          child: _buildDesktopContactPanel(),
                                        ),
                                        const SizedBox(height: 18),
                                        FadeTransition(
                                          opacity: _copyFade,
                                          child: const Text(
                                            'Tempestades passam. Quem é autorregulável floresce em qualquer tempo.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 21,
                                              height: 1.35,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        _buildDesktopActions(context),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ── Top bar ──────────────────────────────────────────
              FadeTransition(
                opacity: _logoFade,
                child: Row(
                  children: [
                    Hero(
                      tag: 'auth-logo',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const _AnimatedPlantLogo(size: 42),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'EstufaSmart',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _P.dark,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Hero icon cluster ─────────────────────────────────
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _P.mint.withValues(alpha: 0.18),
                            ),
                          ),
                          Container(
                            width: 148,
                            height: 148,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _P.mint.withValues(alpha: 0.28),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_P.deep, _P.dark],
                              ),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                          // Satellite icons
                          Positioned(
                            top: 16,
                            right: 24,
                            child: _MiniIconBadge(
                              icon: Icons.thermostat_rounded,
                              color: _P.deep,
                            ),
                          ),
                          Positioned(
                            bottom: 22,
                            right: 18,
                            child: _MiniIconBadge(
                              icon: Icons.water_drop_rounded,
                              color: const Color(0xFF3BA8C5),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 22,
                            child: _MiniIconBadge(
                              icon: Icons.wb_sunny_rounded,
                              color: const Color(0xFFE6A817),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            left: 20,
                            child: _MiniIconBadge(
                              icon: Icons.sensors_rounded,
                              color: _P.mint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _copyFade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A7E69), Color(0xFF0F5E4F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _P.dark.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tempestades passam.\nQuem é autorregulável floresce em qualquer tempo.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Atendimento rápido',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '(11) 4002-8922 • (19) 99999-1234',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Row(
                                children: [
                                  Icon(Icons.mail, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'suporte@estufasmart.com',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _duvidaRapidaController,
                                maxLines: 2,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Digite sua dúvida...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.08),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Colors.white, width: 1.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _enviarDuvidaRapida,
                                  icon: const Icon(Icons.send_rounded, size: 16),
                                  label: const Text('Enviar dúvida'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: _buttonScale,
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      _ecoRoute(LoginScreen()),
                                    ),
                                    icon: const Icon(Icons.login_rounded),
                                    label: const Text('Entrar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: _P.dark,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      _ecoRoute(CadastroClientes()),
                                    ),
                                    icon: const Icon(Icons.person_add_alt_1_outlined),
                                    label: const Text('Criar conta'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1.6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RightPanelClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(66, 0)
      ..quadraticBezierTo(-6, size.height * 0.22, 44, size.height * 0.52)
      ..quadraticBezierTo(-8, size.height * 0.80, 66, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureSenha = true;
  bool _loading = false;
  bool? conexaoOk;
  String? ipExterno;

  late final AnimationController _controller;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _fieldOneFade;
  late final Animation<double> _fieldTwoFade;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.38),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.52, curve: Curves.easeOutCubic),
      ),
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.42, curve: Curves.easeIn),
      ),
    );
    _fieldOneFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 0.66, curve: Curves.easeIn),
      ),
    );
    _fieldTwoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.80, curve: Curves.easeIn),
      ),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 1, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
    carregarIpETestar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> carregarIpETestar() async {
    final ip = await IpUtil.carregarIp();
    if (ip == null) {
      if (mounted) {
        setState(() {
          conexaoOk = false;
          ipExterno = null;
        });
      }
      return;
    }

    final sucesso = await ApiService.testarConexao(ip);
    if (mounted) {
      setState(() {
        conexaoOk = sucesso;
        ipExterno = ip;
      });
    }
  }

  void _verificarLogin() async {
    if (conexaoOk != true || ipExterno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conexao com a API falhou. Verifique o IP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final sucesso = await ApiService.autenticarUsuario(
      ipExterno!,
      _usuarioController.text,
      _senhaController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    if (sucesso.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo, ${_usuarioController.text}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder:
              (_, __, ___) => HomePage(
                cpfLogado:
                    sucesso.cpf ??
                    _usuarioController.text.replaceAll(RegExp(r'\D'), ''),
                administrador: sucesso.administrador,
                pendenciasAprovacao: sucesso.pendenciasAprovacao,
              ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_person_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Acesso Negado'),
                ],
              ),
              content: Text(sucesso.mensagem),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  Widget _connectionChip() {
    if (conexaoOk == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: Colors.amber.shade700),
          const SizedBox(width: 6),
          Text(
            'Verificando...',
            style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          conexaoOk! ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
          size: 16,
          color: conexaoOk! ? _P.deep : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          conexaoOk! ? 'Servidor conectado' : 'Sem conexao',
          style: TextStyle(
            fontSize: 12,
            color: conexaoOk! ? _P.deep : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EcoScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: _P.dark),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'auth-logo',
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _P.light,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _P.mint.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/imagesE/login.gif',
                                width: 88,
                                height: 88,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Bem-vindo de volta',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _P.dark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _connectionChip(),
                          const SizedBox(height: 26),
                          FadeTransition(
                            opacity: _fieldOneFade,
                            child: TextFormField(
                              controller: _usuarioController,
                              textInputAction: TextInputAction.next,
                              decoration: _ecoInput(
                                'Usuario',
                                Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Usuario e obrigatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fieldTwoFade,
                            child: TextFormField(
                              controller: _senhaController,
                              obscureText: _obscureSenha,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _verificarLogin(),
                              decoration: _ecoInput(
                                'Senha',
                                Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureSenha = !_obscureSenha;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureSenha
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _P.deep,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Senha e obrigatoria';
                                }
                                if (value.length < 3) {
                                  return 'Senha deve ter no minimo 3 caracteres';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 26),
                          FadeTransition(
                            opacity: _buttonFade,
                            child: SizedBox(
                              width: double.infinity,
                              child:
                                  _loading
                                      ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(
                                            color: _P.deep,
                                          ),
                                        ),
                                      )
                                      : _EcoButton(
                                        label: 'Entrar',
                                        icon: Icons.login_rounded,
                                        filled: true,
                                        width: double.infinity,
                                        onTap: _verificarLogin,
                                      ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _buttonFade,
                            child: TextButton(
                              onPressed:
                                  () => Navigator.pushReplacement(
                                    context,
                                    _ecoRoute(
                                      CadastroClientes(),
                                      beginOffset: const Offset(-0.16, 0),
                                    ),
                                  ),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Nao tem conta? ',
                                  style: TextStyle(color: _P.text),
                                  children: [
                                    TextSpan(
                                      text: 'Criar agora',
                                      style: TextStyle(
                                        color: _P.deep,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ),
    );
  }
}

class CadastroClientes extends StatefulWidget {
  const CadastroClientes({super.key});

  @override
  State<CadastroClientes> createState() => _CadastroClientesState();
}

class _CadastroClientesState extends State<CadastroClientes>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<Cliente> _clientes = [];

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

  bool? conexaoOk;
  String? ipExterno;
  String _sexo = 'Masculino';
  bool _ativo = false;
  bool _aceitouTermos = false;
  bool _obscureSenha = true;

  late final AnimationController _controller;
  late final Animation<double> _sectionOne;
  late final Animation<double> _sectionTwo;
  late final Animation<double> _sectionThree;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sectionOne = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _sectionTwo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.76, curve: Curves.easeOutCubic),
      ),
    );
    _sectionThree = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    carregarIpETestar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    _cepController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  Future<void> carregarIpETestar() async {
    final ip = await IpUtil.carregarIp();
    if (ip == null) {
      if (mounted) {
        setState(() {
          conexaoOk = false;
          ipExterno = null;
        });
      }
      return;
    }

    final sucesso = await ApiService.testarConexao(ip);
    if (mounted) {
      setState(() {
        conexaoOk = sucesso;
        ipExterno = ip;
      });
    }
  }

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
      _obscureSenha = true;
    });
  }

  void _mostrarClientes() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(Icons.people_outline, color: _P.deep),
                SizedBox(width: 8),
                Text('Clientes Cadastrados'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children:
                    _clientes.map((cliente) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _P.light,
                          border: Border.all(color: _P.mint),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informacoes Pessoais',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Nome: ${cliente.nome}'),
                            Text('Telefone: ${cliente.telefone}'),
                            Text('Email: ${cliente.email}'),
                            Text('CPF: ${cliente.cpf}'),
                            Text('Sexo: ${cliente.sexo}'),
                            const Divider(),
                            const Text(
                              'Endereco',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('CEP: ${cliente.cep}'),
                            Text('Cidade: ${cliente.cidade}'),
                            Text('Bairro: ${cliente.bairro}'),
                            Text('Numero: ${cliente.numero}'),
                            if (cliente.complemento.isNotEmpty)
                              Text('Complemento: ${cliente.complemento}'),
                            const Divider(),
                            const Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Ativo: ${cliente.ativo ? 'Sim' : 'Nao'}'),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _cadastrarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_aceitouTermos) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Atencao'),
              content: const Text('Voce deve aceitar os termos.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendi'),
                ),
              ],
            ),
      );
      return;
    }

    if (conexaoOk != true || ipExterno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conexao com a API falhou. Verifique o IP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final novo = Cliente(
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

    if (!mounted) {
      return;
    }

    if (resultado != null) {
      _clientes.add(novo);
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Sucesso'),
                ],
              ),
              content: Text(resultado['mensagem'] ?? 'Cliente cadastrado!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      _limparCampos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao cadastrar cliente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _animatedSection(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.10, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  void _formatTelefone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    var formatted = digits;
    if (digits.length >= 2) {
      formatted = '${digits.substring(0, 2)} ';
      if (digits.length >= 7) {
        formatted += '${digits.substring(2, 7)}-${digits.substring(7)}';
      } else if (digits.length > 2) {
        formatted += digits.substring(2);
      }
    }

    _telefoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _formatCpf(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    var formatted = digits;
    if (digits.length >= 3) {
      formatted = digits.substring(0, 3);
      if (digits.length >= 6) {
        formatted += '.${digits.substring(3, 6)}';
        if (digits.length >= 9) {
          formatted += '.${digits.substring(6, 9)}';
          if (digits.length >= 10) {
            formatted += '-${digits.substring(9)}';
          }
        } else if (digits.length > 6) {
          formatted += '.${digits.substring(6)}';
        }
      } else if (digits.length > 3) {
        formatted += '.${digits.substring(3)}';
      }
    }

    _cpfController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _formatCep(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    var formatted = digits;
    if (digits.length > 5) {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    _cepController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EcoScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: _P.dark),
        title: const Text(
          'Criar conta',
          style: TextStyle(color: _P.dark, fontWeight: FontWeight.w700),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              children: [
                _animatedSection(
                  _sectionOne,
                  _SectionCard(
                    title: 'Informacoes Pessoais',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          textInputAction: TextInputAction.next,
                          decoration: _ecoInput('Nome', Icons.person_outline),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Nome e obrigatorio'
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _telefoneController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          onChanged: _formatTelefone,
                          decoration: _ecoInput(
                            'Telefone (00 00000-0000)',
                            Icons.phone_outlined,
                          ),
                          validator:
                              (value) =>
                                  RegExp(
                                        r'^\d{2} \d{5}-\d{4}$',
                                      ).hasMatch(value ?? '')
                                      ? null
                                      : 'Telefone invalido',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _ecoInput('Email', Icons.email_outlined),
                          validator: (value) {
                            const regex = r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$';
                            if (value == null || value.isEmpty) {
                              return 'Email e obrigatorio';
                            }
                            if (!RegExp(regex).hasMatch(value)) {
                              return 'Email invalido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cpfController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          onChanged: _formatCpf,
                          decoration: _ecoInput(
                            'CPF (000.000.000-00)',
                            Icons.badge_outlined,
                          ),
                          validator:
                              (value) =>
                                  RegExp(
                                        r'^\d{3}\.\d{3}\.\d{3}-\d{2}$',
                                      ).hasMatch(value ?? '')
                                      ? null
                                      : 'CPF invalido',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscureSenha,
                          textInputAction: TextInputAction.next,
                          decoration: _ecoInput(
                            'Senha',
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureSenha = !_obscureSenha;
                                });
                              },
                              icon: Icon(
                                _obscureSenha
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _P.deep,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Senha e obrigatoria';
                            }
                            if (value.length < 3) {
                              return 'Senha deve ter no minimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _sexo,
                          dropdownColor: Colors.white,
                          decoration: _ecoInput('Sexo', Icons.wc_outlined),
                          items:
                              const ['Masculino', 'Feminino', 'Outro']
                                  .map(
                                    (sexo) => DropdownMenuItem<String>(
                                      value: sexo,
                                      child: Text(sexo),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sexo = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _animatedSection(
                  _sectionTwo,
                  _SectionCard(
                    title: 'Endereco',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _cepController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          onChanged: _formatCep,
                          decoration: _ecoInput(
                            'CEP (00000-000)',
                            Icons.map_outlined,
                          ),
                          validator:
                              (value) =>
                                  RegExp(r'^\d{5}-\d{3}$').hasMatch(value ?? '')
                                      ? null
                                      : 'CEP invalido',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cidadeController,
                          textInputAction: TextInputAction.next,
                          decoration: _ecoInput(
                            'Cidade (ex: Limeira - SP)',
                            Icons.location_city_outlined,
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Cidade e obrigatoria'
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bairroController,
                          textInputAction: TextInputAction.next,
                          decoration: _ecoInput(
                            'Bairro',
                            Icons.home_work_outlined,
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Bairro e obrigatorio'
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _numeroController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: _ecoInput(
                            'Numero da casa',
                            Icons.format_list_numbered_rounded,
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Numero e obrigatorio'
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _complementoController,
                          textInputAction: TextInputAction.done,
                          decoration: _ecoInput(
                            'Complemento',
                            Icons.edit_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _animatedSection(
                  _sectionThree,
                  _SectionCard(
                    title: 'Confirmacao',
                    icon: Icons.check_circle_outline_rounded,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: _P.deep,
                          title: const Text(
                            'Conta ativa',
                            style: TextStyle(color: _P.text),
                          ),
                          value: _ativo,
                          onChanged: (value) {
                            setState(() {
                              _ativo = value;
                            });
                          },
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _P.deep,
                          title: const Text(
                            'Aceito os termos de uso',
                            style: TextStyle(color: _P.text),
                          ),
                          value: _aceitouTermos,
                          onChanged: (value) {
                            setState(() {
                              _aceitouTermos = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _EcoButton(
                                label: 'Cadastrar',
                                icon: Icons.check_rounded,
                                filled: true,
                                onTap: _cadastrarCliente,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _EcoButton(
                                label: 'Limpar',
                                icon: Icons.refresh_rounded,
                                filled: false,
                                onTap: _limparCampos,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _EcoButton(
                            label: 'Mostrar clientes',
                            icon: Icons.list_alt_rounded,
                            filled: false,
                            onTap: _mostrarClientes,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final String text;

  const NavItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
