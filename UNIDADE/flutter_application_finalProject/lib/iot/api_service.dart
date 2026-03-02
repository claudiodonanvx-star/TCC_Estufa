import 'package:http/http.dart' as http;
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/Cultivo.dart';
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
