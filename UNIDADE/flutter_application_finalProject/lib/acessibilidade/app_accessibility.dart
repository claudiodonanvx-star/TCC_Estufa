import 'package:flutter/material.dart';

class AppAccessibility extends ChangeNotifier {
  double textScale = 1.0;
  bool highContrast = false;

  void increaseText() {
    if (textScale < 1.6) {
      textScale = (textScale + 0.1).clamp(1.0, 1.6);
      notifyListeners();
    }
  }

  void decreaseText() {
    if (textScale > 0.8) {
      textScale = (textScale - 0.1).clamp(0.8, 1.6);
      notifyListeners();
    }
  }

  void toggleContrast() {
    highContrast = !highContrast;
    notifyListeners();
  }

  void reset() {
    textScale = 1.0;
    highContrast = false;
    notifyListeners();
  }
}

final appAccessibility = AppAccessibility();

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appAccessibility,
      builder: (context, _) {
        final highContrast = appAccessibility.highContrast;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(Icons.accessibility_new_rounded, size: 48),
            const SizedBox(height: 10),
            const Text(
              'Acessibilidade',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Personalize a leitura e o contraste da aplicação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.contrast_rounded),
                title: const Text('Alto contraste'),
                subtitle: const Text('Aumenta a diferença entre fundo e texto'),
                value: highContrast,
                onChanged: (_) => appAccessibility.toggleContrast(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.text_decrease_rounded),
                title: const Text('Diminuir texto'),
                onTap: appAccessibility.decreaseText,
                trailing: Text('${(appAccessibility.textScale * 100).round()}%'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.text_increase_rounded),
                title: const Text('Aumentar texto'),
                onTap: appAccessibility.increaseText,
                trailing: Text('${(appAccessibility.textScale * 100).round()}%'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: appAccessibility.reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Restaurar padrão'),
            ),
          ],
        );
      },
    );
  }
}