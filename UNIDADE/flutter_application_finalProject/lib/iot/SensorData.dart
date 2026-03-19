class SensorData {
  final double? temperatura;
  final double? umidade;
  final double? umidadeSolo;
  final String? dataHora;
  final String? significado; // ← novo campo

  SensorData({
    required this.temperatura,
    required this.umidade,
    this.umidadeSolo,
    this.dataHora,
    this.significado,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperatura: json['temperatura']?.toDouble() ?? 0.0,
      umidade: json['umidade']?.toDouble() ?? 0.0,
      umidadeSolo: json['umidadeSolo']?.toDouble() ?? 0.0,
      dataHora: json['dataHora']?.toString(),
      significado: json['significado']?.toString(), // ← novo campo
    );
  }
}
