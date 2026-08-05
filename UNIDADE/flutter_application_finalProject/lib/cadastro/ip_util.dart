import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_application_1/cadastro/api_settings.dart';

class IpUtil {
  static const String hostedApiUrl = 'https://api-estufa.onrender.com';

  static Future<String?> carregarIp() async {
    // Primeiro, tenta carregar a URL salva nas configurações
    final urlSalva = await ApiSettings.obterUrlApi();
    if (urlSalva != hostedApiUrl) {
      // Se há uma URL customizada salva, usa ela
      return urlSalva;
    }

    // Caso contrário, tenta carregar do arquivo de assets
    for (final caminho in ['assets/IPAPI/ipexterno.txt', 'assets/ipexterno.txt']) {
      try {
        final conteudo = await rootBundle.loadString(caminho);
        final normalizado = _normalizarBaseUrl(conteudo);
        if (normalizado != null) {
          final ehLocal = normalizado.contains('localhost') ||
              normalizado.contains('127.0.0.1');
          if (ehLocal) return hostedApiUrl;
          return normalizado;
        }
      } catch (_) {}
    }

    print('⚠️ Erro ao ler IP do asset: nenhum caminho válido encontrado');
    return hostedApiUrl;
  }

  static String? _normalizarBaseUrl(String valor) {
    var ip = valor.trim();
    if (ip.isEmpty) return null;

    if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
      if (ip.startsWith('localhost') || ip.startsWith('127.0.0.1')) {
        ip = 'http://$ip';
      } else {
        ip = 'https://$ip';
      }
    }

    if (ip.endsWith('/')) {
      ip = ip.substring(0, ip.length - 1);
    }

    return ip;
  }
}
