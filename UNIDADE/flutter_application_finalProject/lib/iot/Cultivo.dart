class Cultivo {
  final int id;
  final String nome;
  final String tipo;
  final double temperaturaMinima;
  final double temperaturaMaxima;
  final double umidadeMinima;
  final double umidadeMaxima;
  final double umidadeSoloMinima;
  final double umidadeSoloMaxima;
  final bool habilitada;

  Cultivo({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.temperaturaMinima,
    required this.temperaturaMaxima,
    required this.umidadeMinima,
    required this.umidadeMaxima,
    required this.umidadeSoloMinima,
    required this.umidadeSoloMaxima,
    required this.habilitada,
  });

  factory Cultivo.fromJson(Map<String, dynamic> json) {
    return Cultivo(
      id: json['id'],
      nome: json['nome'],
      tipo: json['tipo'],
      temperaturaMinima: json['temperaturaMinima'].toDouble(),
      temperaturaMaxima: json['temperaturaMaxima'].toDouble(),
      umidadeSoloMinima: (json['umidadeSoloMinima'] ?? 30.0).toDouble(),
      umidadeSoloMaxima: (json['umidadeSoloMaxima'] ?? 70.0).toDouble(),
      umidadeMinima: json['umidadeMinima'].toDouble(),
      umidadeMaxima: json['umidadeMaxima'].toDouble(),
      habilitada: json['habilitada'] == true || json['habilitada'] == 1,
    );
  }
}
