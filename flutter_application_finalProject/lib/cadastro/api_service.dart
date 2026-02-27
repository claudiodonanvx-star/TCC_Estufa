import 'dart:convert';
import 'package:flutter_application_1/cadastro/cliente.dart';
import 'package:http/http.dart' as http;

class LoginResultado {
  final bool sucesso;
  final String mensagem;
  final String? cpf;
  final bool administrador;
  final int pendenciasAprovacao;

  LoginResultado({
    required this.sucesso,
    required this.mensagem,
    this.cpf,
    this.administrador = false,
    this.pendenciasAprovacao = 0,
  });
}

class ApiService {
  static String _normalizarBaseUrl(String ip) {
    var base = ip.trim();
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  static Future<bool> testarConexao(String ip) async {
    try {
      final baseUrl = _normalizarBaseUrl(ip);
      final res = await http.get(Uri.parse('$baseUrl/api/ping'));
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (e) {
      print('⚠️ Erro ao testar conexão: $e');
      return false;
    }
  }

  static Future<LoginResultado> autenticarUsuario(String ip, String usuario, String senha) async {
    if (ip.isEmpty) {
      return LoginResultado(sucesso: false, mensagem: 'IP inválido.');
    }

    final baseUrl = _normalizarBaseUrl(ip);
    final url = Uri.parse('$baseUrl/api/usuarios/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'login': usuario,
          'senha': senha,
        }),
      );

      Map<String, dynamic> payload = {};
      if (response.body.isNotEmpty) {
        try {
          payload = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          payload = {'mensagem': response.body};
        }
      }

      if (response.statusCode == 200) {
        return LoginResultado(
          sucesso: true,
          mensagem: payload['mensagem']?.toString() ?? 'Login bem-sucedido',
          cpf: payload['cpf']?.toString(),
          administrador: payload['administrador'] == true,
          pendenciasAprovacao:
              int.tryParse('${payload['pendenciasAprovacao'] ?? 0}') ?? 0,
        );
      }

      return LoginResultado(
        sucesso: false,
        mensagem: payload['mensagem']?.toString() ?? 'Falha ao autenticar.',
      );
    } catch (e) {
      return LoginResultado(sucesso: false, mensagem: 'Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>?> cadastrarCliente(String ip, Cliente cliente) async {
  if (ip.isEmpty) return null;

  final baseUrl = _normalizarBaseUrl(ip);
  final url = Uri.parse('$baseUrl/api/clientes/cadastro');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(cliente.toJson()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Erro ao cadastrar: ${response.body}');
      return null;
    }
  } catch (e) {
    print('⚠️ Erro de conexão: $e');
    return null;
  }
}

}
