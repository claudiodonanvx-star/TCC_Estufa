import 'package:flutter_application_1/iot/Alerta.dart';
import 'package:flutter_application_1/iot/Cultivo.dart';
import 'package:flutter_application_1/iot/RelatorioDiario.dart';
import 'package:flutter_application_1/iot/SensorData.dart';
import 'package:flutter_application_1/iot/api_service.dart' as iot;

enum _TipoFerramenta {
  leituras,
  cultivoAtual,
  cultivos,
  alertas,
  relatorios,
  atuadores,
  modoAutomatico,
  acionarAtuador,
  desligamentoNaoDisponivel,
}

class FerramentaInterna {
  const FerramentaInterna._(
    this._tipo, {
    String? periodo,
    bool? modoAutomatico,
    String? atuador,
    int? duracaoSegundos,
  }) : _periodo = periodo,
       _modoAutomatico = modoAutomatico,
       _atuador = atuador,
       _duracaoSegundos = duracaoSegundos;

  final _TipoFerramenta _tipo;
  final String? _periodo;
  final bool? _modoAutomatico;
  final String? _atuador;
  final int? _duracaoSegundos;

  bool get exigeConfirmacao =>
      _tipo == _TipoFerramenta.modoAutomatico ||
      _tipo == _TipoFerramenta.acionarAtuador;

    bool get executarLocalmente =>
      exigeConfirmacao || _tipo == _TipoFerramenta.desligamentoNaoDisponivel;

  String get descricaoConfirmacao {
    if (_tipo == _TipoFerramenta.modoAutomatico) {
      return 'Alterar o modo da estufa para ${_modoAutomatico! ? 'automático' : 'manual'}?';
    }
    final nome = switch (_atuador) {
      'bomba' => 'bomba',
      'cooler' => 'cooler',
      _ => 'aquecedor',
    };
    return 'Acionar $nome por $_duracaoSegundos segundos?';
  }

  static FerramentaInterna? interpretar(String texto) {
    final pergunta = _normalizar(texto);
    final pedeAtivar = RegExp(r'\b(liga|ligar|ligue|aciona|acionar|acione|ativa|ativar|ative)\b')
        .hasMatch(pergunta);
    final pedeDesativar = RegExp(r'\b(desliga|desligar|desligue|desativa|desativar|desative|pare)\b')
        .hasMatch(pergunta);
    final pedeAlterarModo = RegExp(r'\b(coloca|coloque|muda|mude|altera|altere|define|defina)\b')
      .hasMatch(pergunta);

    if (_temAlgum(pergunta, ['modo automatico', 'modo manual']) &&
      (pedeAtivar || pedeDesativar || pedeAlterarModo || pergunta.contains('modo manual'))) {
      return FerramentaInterna._(
        _TipoFerramenta.modoAutomatico,
        modoAutomatico: pergunta.contains('modo automatico') && !pedeDesativar,
      );
    }

    if (pedeAtivar || pedeDesativar) {
      final atuador = _detectarAtuador(pergunta);
      if (atuador != null && pedeAtivar) {
        return FerramentaInterna._(
          _TipoFerramenta.acionarAtuador,
          atuador: atuador,
          duracaoSegundos: atuador == 'bomba' ? 5 : atuador == 'temperatura' ? 35 : 55,
        );
      }
      if (atuador != null && pedeDesativar) {
        return FerramentaInterna._(
          _TipoFerramenta.desligamentoNaoDisponivel,
          atuador: atuador,
        );
      }
    }

    if (_temAlgum(pergunta, ['relatorio', 'relatorios'])) {
      final periodo = pergunta.contains('mensal')
          ? 'mensal'
          : pergunta.contains('anual') || pergunta.contains('ano')
              ? 'anual'
              : 'semanal';
      return FerramentaInterna._(_TipoFerramenta.relatorios, periodo: periodo);
    }
    if (_temAlgum(pergunta, ['alerta', 'notificacao', 'critico'])) {
      return const FerramentaInterna._(_TipoFerramenta.alertas);
    }
    if (_temAlgum(pergunta, ['cultivos cadastrados', 'listar cultivos', 'lista de cultivos', 'plantas cadastradas'])) {
      return const FerramentaInterna._(_TipoFerramenta.cultivos);
    }
    if (_temAlgum(pergunta, ['cultivo atual', 'planta atual', 'cultivo habilitado', 'planta ativa'])) {
      return const FerramentaInterna._(_TipoFerramenta.cultivoAtual);
    }
    if (_temAlgum(pergunta, ['atuadores', 'estado da bomba', 'estado do cooler', 'estado do aquecedor', 'bomba ligada', 'cooler ligado', 'aquecedor ligado', 'modo automatico'])) {
      return const FerramentaInterna._(_TipoFerramenta.atuadores);
    }
    if (_temAlgum(pergunta, ['leitura', 'sensores', 'sensor', 'temperatura atual', 'temperatura agora', 'umidade atual', 'umidade agora', 'umidade do solo atual', 'umidade do solo agora', 'dados da estufa'])) {
      return const FerramentaInterna._(_TipoFerramenta.leituras);
    }
    return null;
  }

  Future<String> executar(String baseUrl) async {
    return switch (_tipo) {
      _TipoFerramenta.leituras => _formatarLeituras(await iot.fetchDados(baseUrl)),
      _TipoFerramenta.cultivoAtual => _formatarCultivo(await iot.fetchCultivoAtual(baseUrl)),
      _TipoFerramenta.cultivos => _formatarCultivos(await iot.fetchCultivos(baseUrl)),
      _TipoFerramenta.alertas => _formatarAlertas(await iot.fetchAlertas(baseUrl)),
      _TipoFerramenta.relatorios => _formatarRelatorios(
          await iot.fetchRelatorios(baseUrl, _periodo ?? 'semanal'),
          _periodo ?? 'semanal',
        ),
      _TipoFerramenta.atuadores => _formatarAtuadores(await iot.fetchEstadoAtuadores(baseUrl)),
      _TipoFerramenta.modoAutomatico => _formatarAtuadores(
          await iot.definirModoAutomatico(baseUrl, _modoAutomatico!),
        ),
      _TipoFerramenta.acionarAtuador => _formatarAtuadores(
          await iot.acionarAtuadorManual(
            baseUrl,
            _atuador!,
            duracaoSegundos: _duracaoSegundos!,
          ),
        ),
      _TipoFerramenta.desligamentoNaoDisponivel =>
        'A API da unidade não oferece desligamento imediato do atuador. '
        'O acionamento manual expira automaticamente após o tempo limite.',
    };
  }

  static String _formatarLeituras(List<SensorData> leituras) {
    if (leituras.isEmpty) return 'Ainda não há leituras de sensores disponíveis.';
    final ultima = leituras.last;
    return 'Leitura mais recente (${ultima.dataHora ?? 'horário não informado'}): '
        'temperatura ${_valor(ultima.temperatura, '°C')}, '
        'umidade do ar ${_valor(ultima.umidade, '%')}, '
        'umidade do solo ${_valor(ultima.umidadeSolo, '%')}.';
  }

  static String _formatarCultivo(Cultivo? cultivo) {
    if (cultivo == null) return 'Não há cultivo habilitado no momento.';
    return 'Cultivo ativo: ${cultivo.nome} (${cultivo.tipo}). '
        'Temperatura: ${cultivo.temperaturaMinima} a ${cultivo.temperaturaMaxima} °C; '
        'umidade do ar: ${cultivo.umidadeMinima} a ${cultivo.umidadeMaxima}%; '
        "umidade do solo: ${cultivo.umidadeSoloMinima} a ${cultivo.umidadeSoloMaxima}%.";
  }

  static String _formatarCultivos(List<Cultivo> cultivos) {
    if (cultivos.isEmpty) return 'Não há cultivos cadastrados.';
    return 'Cultivos cadastrados: ${cultivos.map((cultivo) => '${cultivo.nome}${cultivo.habilitada ? ' (ativo)' : ''}').join(', ')}.';
  }

  static String _formatarAlertas(List<Alerta> alertas) {
    if (alertas.isEmpty) return 'Não há alertas registrados.';
    return 'Alertas recentes: ${alertas.take(8).map((alerta) =>
        '${alerta.severidade} - ${alerta.tipo}: ${alerta.mensagem ?? _valor(alerta.valor, '')}').join('; ')}.';
  }

  static String _formatarRelatorios(List<RelatorioDiario> relatorios, String periodo) {
    if (relatorios.isEmpty) return 'Não há dados para o relatório $periodo.';
    return 'Resumo do período $periodo: ${relatorios.take(7).map((relatorio) =>
        '${relatorio.dataRef}: temperatura média ${relatorio.tempMedia} °C, '
        'umidade média ${relatorio.umidadeMedia}%, solo ${relatorio.soloMedia}% '
        '(${relatorio.totalLeituras} leituras)').join('; ')}.';
  }

  static String _formatarAtuadores(Map<String, dynamic> estado) {
    String ligado(String chave) => estado[chave] == true ? 'ligado' : 'desligado';
    return 'Modo ${estado['modoAutomatico'] == true ? 'automático' : 'manual'}. '
        'Bomba ${ligado('bombaLigada')}, cooler ${ligado('coolerLigado')}, '
        'aquecedor ${ligado('temperaturaLigada')}.';
  }

  static String _valor(double? valor, String unidade) =>
      valor == null ? 'indisponível' : '$valor$unidade';

  static String? _detectarAtuador(String texto) {
    if (texto.contains('bomba')) return 'bomba';
    if (texto.contains('cooler') || texto.contains('ventilacao')) return 'cooler';
    if (texto.contains('aquecedor') || texto.contains('temperatura')) return 'temperatura';
    return null;
  }

  static bool _temAlgum(String texto, List<String> opcoes) =>
      opcoes.any(texto.contains);

  static String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll(RegExp(r'[áàãâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòõôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}