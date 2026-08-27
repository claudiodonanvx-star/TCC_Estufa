import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/estufa_inteligencia.dart';

void main() {
  group('gerarAlertasInteligentes', () {
    test(
      'gera alerta crítico quando temperatura ultrapassa o limite do cenário',
      () {
        final dados = [
          SensorData(temperatura: 35.0, umidade: 60.0, umidadeSolo: 25.0),
        ];

        final alertas = gerarAlertasInteligentes(dados, CenarioEstufa.padrao);

        expect(
          alertas.any((a) => a.tipo.toUpperCase() == 'TEMPERATURA'),
          isTrue,
        );
        expect(
          alertas.any((a) => a.severidade.toUpperCase() == 'CRITICO'),
          isTrue,
        );
      },
    );

    test('gera previsão de tendência quando há dados em sequência', () {
      final dados = [
        SensorData(temperatura: 24.0, umidade: 70.0, umidadeSolo: 30.0),
        SensorData(temperatura: 26.0, umidade: 68.0, umidadeSolo: 29.0),
        SensorData(temperatura: 28.0, umidade: 65.0, umidadeSolo: 27.0),
      ];

      final resumo = analisarEstufa(dados, CenarioEstufa.padrao);

      expect(resumo.previsaoTemperatura.toLowerCase(), contains('subir'));
      expect(resumo.previsaoUmidade.toLowerCase(), contains('cair'));
    });
  });
}
