import 'package:shared_preferences/shared_preferences.dart';

class ApiSettings {
  static const String _keyApiUrl = 'api_url';
  static const String _defaultApiUrl = 'https://api-estufa.onrender.com';

  static Future<String> obterUrlApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiUrl) ?? _defaultApiUrl;
  }

  static Future<void> salvarUrlApi(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizado = _normalizarUrl(url);
    await prefs.setString(_keyApiUrl, normalizado);
  }

  static Future<void> resetarUrlApi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiUrl);
  }

  static String _normalizarUrl(String valor) {
    var url = valor.trim();
    if (url.isEmpty) return _defaultApiUrl;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }
}
