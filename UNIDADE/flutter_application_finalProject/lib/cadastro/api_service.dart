import 'dart:convert';
import 'package:flutter_application_1/cadastro/cliente.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

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
  static const _secureStorage = FlutterSecureStorage();

  static String _normalizarBaseUrl(String ip) {
    var base = ip.trim();
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      if (base.startsWith('localhost') || base.startsWith('127.0.0.1')) {
        base = 'http://$base';
      } else {
        base = 'https://$base';
      }
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
        final token = payload['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _secureStorage.write(key: 'estufa_jwt', value: token);
        }
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
  final token = await _secureStorage.read(key: 'estufa_jwt');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(cliente.toJsonCadastro()),
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

  static Future<void> encerrarSessao() async {
    await _secureStorage.delete(key: 'estufa_jwt');
  }

  static Future<WebSocketChannel> conectarSincronizacao(String ip) async {
    final baseUrl = _normalizarBaseUrl(ip);
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/ws/sincronizacao');
    return WebSocketChannel.connect(uri);
  }

}
