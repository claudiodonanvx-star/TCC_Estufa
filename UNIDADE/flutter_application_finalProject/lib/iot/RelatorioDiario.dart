class RelatorioDiario {
  final String dataRef; // "2026-05-01"
  final double tempMedia;
  final double tempMinima;
  final double tempMaxima;
  final double umidadeMedia;
  final double umidadeMinima;
  final double umidadeMaxima;
  final double soloMedia;
  final double soloMinima;
  final double soloMaxima;
  final int totalLeituras;

  RelatorioDiario({
    required this.dataRef,
    required this.tempMedia,
    required this.tempMinima,
    required this.tempMaxima,
    required this.umidadeMedia,
    required this.umidadeMinima,
    required this.umidadeMaxima,
    required this.soloMedia,
    required this.soloMinima,
    required this.soloMaxima,
    required this.totalLeituras,
  });

  factory RelatorioDiario.fromJson(Map<String, dynamic> json) {
    return RelatorioDiario(
      dataRef: (json['dataRef'] ?? '').toString(),
      tempMedia: (json['tempMedia'] ?? 0).toDouble(),
      tempMinima: (json['tempMinima'] ?? 0).toDouble(),
      tempMaxima: (json['tempMaxima'] ?? 0).toDouble(),
      umidadeMedia: (json['umidadeMedia'] ?? 0).toDouble(),
      umidadeMinima: (json['umidadeMinima'] ?? 0).toDouble(),
      umidadeMaxima: (json['umidadeMaxima'] ?? 0).toDouble(),
      soloMedia: (json['soloMedia'] ?? 0).toDouble(),
      soloMinima: (json['soloMinima'] ?? 0).toDouble(),
      soloMaxima: (json['soloMaxima'] ?? 0).toDouble(),
      totalLeituras: (json['totalLeituras'] ?? 0) as int,
    );
  }

  // Formato curto para eixo X do gráfico: "05/01"
  String get labelCurto {
    if (dataRef.length >= 10) {
      return dataRef.substring(5).replaceAll('-', '/');
    }
    return dataRef;
  }
}
