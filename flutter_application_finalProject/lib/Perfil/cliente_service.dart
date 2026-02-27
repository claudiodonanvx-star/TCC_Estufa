import 'dart:convert';
import 'package:flutter_application_1/cadastro/cliente.dart';
import 'package:flutter_application_1/cadastro/ip_util.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/cadastro/api_service.dart';

class ClientePendenteDto {
  final int id;
  final String nome;
  final String cpf;
  final String email;
  final String statusCadastro;

  ClientePendenteDto({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.statusCadastro,
  });

  factory ClientePendenteDto.fromJson(Map<String, dynamic> json) {
    return ClientePendenteDto(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      nome: json['nome']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      statusCadastro: json['statusCadastro']?.toString() ?? '',
    );
  }
}

class ClienteService {
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

  static Future<String?> _carregarBaseUrlValida() async {
    final ip = await IpUtil.carregarIp();
    if (ip == null || ip.isEmpty) {
      return null;
    }
    final baseUrl = _normalizarBaseUrl(ip);
    final conectado = await ApiService.testarConexao(baseUrl);
    if (!conectado) {
      return null;
    }
    return baseUrl;
  }

  static Future<List<Cliente>> buscarClientes() async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      print('⚠️ IP inválido ou não carregado');
      return [];
    }

    final url = Uri.parse('$baseUrl/api/clientes/mostrar');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList.map((json) => Cliente.fromJson(json)).toList();
        } else {
          print('❌ Resposta não é JSON: ${response.body}');
          return [];
        }
      } else {
        print('❌ Erro ao buscar clientes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('⚠️ Erro de requisição: $e');
      return [];
    }
  }

  static Future<Cliente?> buscarClientePorCpf(String cpf) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clientes/por-cpf/$cpf'),
      );

      if (response.statusCode == 200) {
        return Cliente.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('⚠️ Erro ao buscar cliente por CPF: $e');
    }

    return null;
  }

  static Future<bool> atualizarCliente(Cliente cliente, String requesterCpf) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      print('⚠️ IP inválido ou não carregado');
      return false;
    }

    final url = Uri.parse(
      '$baseUrl/api/clientes/atualizar/${cliente.cpf}?requesterCpf=$requesterCpf',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(cliente.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erro de conexão: $e');
      return false;
    }
  }

  static Future<bool> removerCliente(String cpf, String requesterCpf) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/clientes/$cpf?requesterCpf=$requesterCpf'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erro ao remover cliente: $e');
      return false;
    }
  }

  static Future<List<ClientePendenteDto>> buscarPendentes(String adminCpf) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clientes/pendentes?adminCpf=$adminCpf'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ClientePendenteDto.fromJson(e)).toList();
      }
    } catch (e) {
      print('⚠️ Erro ao buscar pendentes: $e');
    }

    return [];
  }

  static Future<int> quantidadePendentes(String adminCpf) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      return 0;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clientes/pendentes/quantidade?adminCpf=$adminCpf'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return int.tryParse('${data['quantidade'] ?? 0}') ?? 0;
      }
    } catch (e) {
      print('⚠️ Erro ao consultar quantidade de pendências: $e');
    }

    return 0;
  }

  static Future<bool> aprovarPendente(int id, String adminCpf) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/clientes/pendentes/$id/aprovar?adminCpf=$adminCpf'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erro ao aprovar pendência: $e');
      return false;
    }
  }

  static Future<bool> recusarPendente(int id, String adminCpf, {String? motivo}) async {
    final baseUrl = await _carregarBaseUrlValida();
    if (baseUrl == null) {
      return false;
    }

    final motivoParam = (motivo ?? '').trim();
    final query =
        motivoParam.isEmpty
            ? ''
            : '&motivo=${Uri.encodeQueryComponent(motivoParam)}';

    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/clientes/pendentes/$id/recusar?adminCpf=$adminCpf$query',
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erro ao recusar pendência: $e');
      return false;
    }
  }
}
