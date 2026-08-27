import 'package:flutter_application_1/iot/Alerta.dart';
import 'package:flutter_application_1/iot/SensorData.dart';

class CenarioEstufa {
  final String nome;
  final double temperaturaMin;
  final double temperaturaMax;
  final double umidadeMin;
  final double umidadeMax;
  final double umidadeSoloMin;
  final double umidadeSoloMax;

  const CenarioEstufa({
    required this.nome,
    required this.temperaturaMin,
    required this.temperaturaMax,
    required this.umidadeMin,
    required this.umidadeMax,
    required this.umidadeSoloMin,
    required this.umidadeSoloMax,
  });

  static const padrao = CenarioEstufa(
    nome: 'Padrão',
    temperaturaMin: 18,
    temperaturaMax: 30,
    umidadeMin: 55,
    umidadeMax: 85,
    umidadeSoloMin: 20,
    umidadeSoloMax: 80,
  );

  static const verao = CenarioEstufa(
    nome: 'Verão',
    temperaturaMin: 20,
    temperaturaMax: 32,
    umidadeMin: 50,
    umidadeMax: 80,
    umidadeSoloMin: 22,
    umidadeSoloMax: 78,
  );

  static const inverno = CenarioEstufa(
    nome: 'Inverno',
    temperaturaMin: 15,
    temperaturaMax: 24,
    umidadeMin: 60,
    umidadeMax: 88,
    umidadeSoloMin: 25,
    umidadeSoloMax: 82,
  );
}

class ResumoEstufa {
  final String status;
  final String previsaoTemperatura;
  final String previsaoUmidade;
  final double mediaTemperatura;
  final double mediaUmidade;
  final double mediaUmidadeSolo;
  final int alertasCriticos;
  final int alertasAtencao;

  const ResumoEstufa({
    required this.status,
    required this.previsaoTemperatura,
    required this.previsaoUmidade,
    required this.mediaTemperatura,
    required this.mediaUmidade,
    required this.mediaUmidadeSolo,
    required this.alertasCriticos,
    required this.alertasAtencao,
  });
}

List<Alerta> gerarAlertasInteligentes(
  List<SensorData> dados,
  CenarioEstufa cenario,
) {
  if (dados.isEmpty) return [];

  final atual = dados.first;
  final alertas = <Alerta>[];

  if (atual.temperatura != null) {
    final valor = atual.temperatura!;
    if (valor > cenario.temperaturaMax) {
      alertas.add(
        _criarAlerta(
          tipo: 'TEMPERATURA',
          severidade:
              valor > cenario.temperaturaMax + 3 ? 'CRITICO' : 'ATENCAO',
          valor: valor,
          limiteMin: cenario.temperaturaMin,
          limiteMax: cenario.temperaturaMax,
          mensagem:
              'Temperatura acima do ideal para o cenario ${cenario.nome}.',
        ),
      );
    } else if (valor < cenario.temperaturaMin) {
      alertas.add(
        _criarAlerta(
          tipo: 'TEMPERATURA',
          severidade:
              valor < cenario.temperaturaMin - 3 ? 'CRITICO' : 'ATENCAO',
          valor: valor,
          limiteMin: cenario.temperaturaMin,
          limiteMax: cenario.temperaturaMax,
          mensagem:
              'Temperatura abaixo do ideal para o cenario ${cenario.nome}.',
        ),
      );
    }
  }

  if (atual.umidade != null) {
    final valor = atual.umidade!;
    if (valor > cenario.umidadeMax) {
      alertas.add(
        _criarAlerta(
          tipo: 'UMIDADE',
          severidade: valor > cenario.umidadeMax + 6 ? 'CRITICO' : 'ATENCAO',
          valor: valor,
          limiteMin: cenario.umidadeMin,
          limiteMax: cenario.umidadeMax,
          mensagem:
              'Umidade elevada e fora da faixa ideal do cenario ${cenario.nome}.',
        ),
      );
    } else if (valor < cenario.umidadeMin) {
      alertas.add(
        _criarAlerta(
          tipo: 'UMIDADE',
          severidade: valor < cenario.umidadeMin - 8 ? 'CRITICO' : 'ATENCAO',
          valor: valor,
          limiteMin: cenario.umidadeMin,
          limiteMax: cenario.umidadeMax,
          mensagem: 'Umidade baixa; risco de estresse hídrico.',
        ),
      );
    }
  }

  if (atual.umidadeSolo != null) {
    final valor = atual.umidadeSolo!;
    if (valor < cenario.umidadeSoloMin) {
      alertas.add(
        _criarAlerta(
          tipo: 'SOLO',
          severidade:
              valor < cenario.umidadeSoloMin - 5 ? 'CRITICO' : 'ATENCAO',
          valor: valor,
          limiteMin: cenario.umidadeSoloMin,
          limiteMax: cenario.umidadeSoloMax,
          mensagem: 'Umidade do solo abaixo do ideal.',
        ),
      );
    }
  }

  return alertas;
}

ResumoEstufa analisarEstufa(List<SensorData> dados, CenarioEstufa cenario) {
  final valoresTemp =
      dados
          .where((d) => d.temperatura != null)
          .map((d) => d.temperatura!)
          .toList();
  final valoresUmidade =
      dados.where((d) => d.umidade != null).map((d) => d.umidade!).toList();
  final valoresSolo =
      dados
          .where((d) => d.umidadeSolo != null)
          .map((d) => d.umidadeSolo!)
          .toList();

  final mediaTemp =
      valoresTemp.isEmpty
          ? 0.0
          : valoresTemp.reduce((a, b) => a + b) / valoresTemp.length;
  final mediaUmidade =
      valoresUmidade.isEmpty
          ? 0.0
          : valoresUmidade.reduce((a, b) => a + b) / valoresUmidade.length;
  final mediaSolo =
      valoresSolo.isEmpty
          ? 0.0
          : valoresSolo.reduce((a, b) => a + b) / valoresSolo.length;

  final tendenciaTemp = _calcularTendencia(valoresTemp);
  final tendenciaUmidade = _calcularTendencia(valoresUmidade);

  String status;
  if (mediaTemp > cenario.temperaturaMax || mediaUmidade < cenario.umidadeMin) {
    status = 'Crítico';
  } else if (mediaTemp > cenario.temperaturaMax - 2 ||
      mediaUmidade < cenario.umidadeMin + 5) {
    status = 'Atenção';
  } else {
    status = 'Estável';
  }

  return ResumoEstufa(
    status: status,
    previsaoTemperatura: _textoPrevisao('temperatura', tendenciaTemp),
    previsaoUmidade: _textoPrevisao('umidade', tendenciaUmidade),
    mediaTemperatura: double.parse(mediaTemp.toStringAsFixed(1)),
    mediaUmidade: double.parse(mediaUmidade.toStringAsFixed(1)),
    mediaUmidadeSolo: double.parse(mediaSolo.toStringAsFixed(1)),
    alertasCriticos: 0,
    alertasAtencao: 0,
  );
}

Alerta _criarAlerta({
  required String tipo,
  required String severidade,
  required double valor,
  required double limiteMin,
  required double limiteMax,
  required String mensagem,
}) {
  return Alerta(
    tipo: tipo,
    severidade: severidade,
    valor: valor,
    limiteMin: limiteMin,
    limiteMax: limiteMax,
    mensagem: mensagem,
    geradoEm: DateTime.now().toIso8601String(),
  );
}

double _calcularTendencia(List<double> valores) {
  if (valores.length < 2) return 0;
  final base = valores.take(5).toList();
  if (base.length < 2) return 0;
  final primeiro = base.first;
  final ultimo = base.last;
  return ultimo - primeiro;
}

String _textoPrevisao(String tipo, double tendencia) {
  if (tipo == 'temperatura') {
    if (tendencia > 0.5) {
      return 'Temperatura deve subir na próxima leitura.';
    }
    if (tendencia < -0.5) {
      return 'Temperatura deve cair na próxima leitura.';
    }
    return 'Temperatura deve se estabilizar.';
  }

  if (tendencia > 1.5) {
    return 'Umidade deve cair na próxima leitura.';
  }
  if (tendencia < -1.5) {
    return 'Umidade deve subir na próxima leitura.';
  }
  return 'Umidade deve se estabilizar.';
}
