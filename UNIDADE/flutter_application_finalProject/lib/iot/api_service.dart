import 'package:http/http.dart' as http;
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/Cultivo.dart';
import 'package:flutter_application_1/iot/Alerta.dart';
import 'package:flutter_application_1/iot/RelatorioDiario.dart';
import 'dart:convert';

Future<List<SensorData>> fetchDados(String ipAtual) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return [];

  final response = await http.get(
    Uri.parse('$ipAtual/api/dados'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => SensorData.fromJson(json)).toList();
  } else {
    throw Exception('Erro ao carregar dados');
  }
}

Future<Cultivo?> fetchCultivoAtual(String ipAtual) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return null;

  final response = await http.get(
    Uri.parse('$ipAtual/api/cultivo-habilitado'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return Cultivo.fromJson(json.decode(response.body));
  } else {
    throw Exception('Erro ao buscar cultivo habilitado');
  }
}

Future<List<Cultivo>> fetchCultivos(String ipAtual) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return [];

  final response = await http.get(
    Uri.parse('$ipAtual/api/cultivos'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => Cultivo.fromJson(json)).toList();
  } else {
    throw Exception('Erro ao carregar cultivos');
  }
}

Future<void> habilitarCultivo(String ipAtual, int id) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;

  final response = await http.put(
    Uri.parse('$ipAtual/api/cultivos/$id/habilitar'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Erro ao habilitar cultivo');
  }
}

Future<void> removerCultivo(String ipAtual, int id) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;

  final response = await http.delete(
    Uri.parse('$ipAtual/api/cultivos/$id'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Erro ao remover cultivo');
  }
}

Future<Cultivo> criarCultivo(
  String ipAtual,
  Map<String, dynamic> cultivoDados,
) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) {
    throw Exception('IP inválido para criar cultivo');
  }

  try {
    final url = Uri.parse('$ipAtual/api/cultivos');
    print('📤 POST para: $url');
    print('📋 Payload: ${json.encode(cultivoDados)}');

    final response = await http
        .post(
          url,
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode(cultivoDados),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Timeout ao criar cultivo (30s)'),
        );

    print('✅ Response status: ${response.statusCode}');
    print('✅ Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cultivo.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Erro ao criar cultivo - Status: ${response.statusCode}\nResposta: ${response.body}',
      );
    }
  } catch (e) {
    throw Exception('Falha ao cadastrar planta: $e');
  }
}

Future<List<Alerta>> fetchAlertas(String ipAtual) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return [];

  final response = await http.get(
    Uri.parse('$ipAtual/api/alertas'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((j) => Alerta.fromJson(j)).toList();
  } else {
    throw Exception('Erro ao carregar alertas');
  }
}

/// periodo: 'semanal', 'mensal' ou 'anual'
Future<List<RelatorioDiario>> fetchRelatorios(
  String ipAtual,
  String periodo,
) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return [];

  final response = await http.get(
    Uri.parse('$ipAtual/api/relatorios/$periodo'),
    headers: {
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((j) => RelatorioDiario.fromJson(j)).toList();
  } else {
    throw Exception('Erro ao carregar relatorios ($periodo)');
  }
}

/// Retorna mapa com status, uptimeMinutos, totalLeituras, alertas24h
Future<Map<String, dynamic>> fetchPingInfo(String ipAtual) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return {};

  try {
    final response = await http
        .get(
          Uri.parse('$ipAtual/api/ping'),
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
  } catch (_) {}
  return {};
}

/// Keep-alive: faz ping silencioso para manter a API acordada no Render.
/// Não lança exceção se falhar — apenas mantém a API respondendo.
Future<void> pingApiKeepAlive(String ipAtual) async {
  if (ipAtual.isEmpty || !ipAtual.startsWith('http')) return;

  try {
    await http
        .get(
          Uri.parse('$ipAtual/api/health'),
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    // Silencio falhas — esta é uma chamada de manutenção
  }
}

Future<Map<String, dynamic>> fetchEstadoAtuadores(String ipAtual) async {
  final response = await http.get(
    Uri.parse('$ipAtual/api/atuadores'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw Exception('Erro ao buscar estado dos atuadores');
  }
  return json.decode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> definirModoAutomatico(
  String ipAtual,
  bool ativo,
) async {
  final response = await http.put(
    Uri.parse('$ipAtual/api/atuadores/modo'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'modoAutomatico': ativo}),
  );

  if (response.statusCode != 200) {
    throw Exception('Erro ao alterar modo de operacao');
  }
  return json.decode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> acionarAtuadorManual(
  String ipAtual,
  String atuador,
) async {
  final response = await http.post(
    Uri.parse('$ipAtual/api/atuadores/$atuador/acionar'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'duracaoSegundos': 55}),
  );

  if (response.statusCode != 200) {
    throw Exception('Erro ao acionar $atuador');
  }
  return json.decode(response.body) as Map<String, dynamic>;
}
