import 'package:flutter/services.dart' show rootBundle;

class IpUtil {
  static Future<String?> carregarIp() async {
    for (final caminho in ['assets/IPAPI/ipexterno.txt', 'assets/ipexterno.txt']) {
      try {
        final conteudo = await rootBundle.loadString(caminho);
        final normalizado = _normalizarBaseUrl(conteudo);
        if (normalizado != null) {
          return normalizado;
        }
      } catch (_) {}
    }

    print('⚠️ Erro ao ler IP do asset: nenhum caminho válido encontrado');
    return null;
  }

  static String? _normalizarBaseUrl(String valor) {
    var ip = valor.trim();
    if (ip.isEmpty) return null;

    if (!ip.startsWith('http://') && !ip.startsWith('https://')) {
      ip = 'http://$ip';
    }

    if (ip.endsWith('/')) {
      ip = ip.substring(0, ip.length - 1);
    }

    return ip;
  }
}
