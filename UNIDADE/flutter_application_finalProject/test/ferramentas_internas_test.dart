import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/ia/ferramentas_internas.dart';

void main() {
  group('FerramentaInterna.interpretar', () {
    test('reconhece consultas internas de sensores e alertas', () {
      expect(FerramentaInterna.interpretar('Qual a temperatura agora?'), isNotNull);
      expect(FerramentaInterna.interpretar('Quais são os alertas críticos?'), isNotNull);
    });

    test('pede confirmação antes de acionar um atuador', () {
      final ferramenta = FerramentaInterna.interpretar('Ligue a bomba');

      expect(ferramenta, isNotNull);
      expect(ferramenta!.exigeConfirmacao, isTrue);
      expect(ferramenta.descricaoConfirmacao, contains('5 segundos'));
    });

    test('pede confirmação para alterar o modo automático', () {
      final ferramenta = FerramentaInterna.interpretar('Mude para modo automático');

      expect(ferramenta, isNotNull);
      expect(ferramenta!.exigeConfirmacao, isTrue);
      expect(ferramenta.descricaoConfirmacao, contains('automático'));
    });

    test('informa quando o desligamento imediato não está disponível', () async {
      final ferramenta = FerramentaInterna.interpretar('Desligue a bomba');

      expect(ferramenta, isNotNull);
      expect(ferramenta!.exigeConfirmacao, isFalse);
      expect(await ferramenta.executar(''), contains('não oferece desligamento imediato'));
    });

    test('mantém perguntas botânicas fora do roteador interno', () {
      expect(FerramentaInterna.interpretar('Como cuidar de tomate?'), isNull);
    });
  });
}