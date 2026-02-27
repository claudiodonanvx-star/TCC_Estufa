import 'dart:convert';
import 'package:http/http.dart' as http;

Future<bool> autenticarUsuario(String ip, String usuario, String senha) async {
  if (ip.isEmpty || !ip.startsWith('http')) return false;

  final url = Uri.parse('$ip/api/usuarios/login');
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

  if (response.statusCode == 200) {
    return response.body == "Login bem-sucedido";
  }

  return false;
}
