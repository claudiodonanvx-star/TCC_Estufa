class Alerta {
  final int? id;
  final String tipo; // TEMPERATURA, UMIDADE, SOLO
  final String severidade; // CRITICO, ATENCAO
  final double valor;
  final double limiteMin;
  final double limiteMax;
  final String? mensagem;
  final String? geradoEm;

  Alerta({
    this.id,
    required this.tipo,
    required this.severidade,
    required this.valor,
    required this.limiteMin,
    required this.limiteMax,
    this.mensagem,
    this.geradoEm,
  });

  bool get isCritico => severidade.toUpperCase() == 'CRITICO';

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'] as int?,
      tipo: (json['tipo'] ?? 'DESCONHECIDO').toString(),
      severidade: (json['severidade'] ?? 'ATENCAO').toString(),
      valor: (json['valor'] ?? 0).toDouble(),
      limiteMin: (json['limiteMin'] ?? 0).toDouble(),
      limiteMax: (json['limiteMax'] ?? 0).toDouble(),
      mensagem: json['mensagem']?.toString(),
      geradoEm: json['geradoEm']?.toString(),
    );
  }
}
