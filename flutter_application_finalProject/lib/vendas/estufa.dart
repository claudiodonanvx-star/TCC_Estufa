class Estufa {
  String _nome = "";
  String _descricao = "";
  String _imagem = "";
  double _preco = 0;
  int _estoque = 0;

  String get nome => _nome;
  set nome(String nome) => _nome = nome;

  String get descricao => _descricao;
  set descricao(String descricao) => _descricao = descricao;

  String get imagem => _imagem;
  set imagem(String imagem) => _imagem = imagem;

  double get preco => _preco;
  set preco(double preco) => _preco = preco;

  int get estoque => _estoque;
  set estoque(int estoque) => _estoque = estoque;

  Estufa({
    required String nome,
    required String descricao,
    required String imagem,
    required double preco,
    required int estoque,
  }) {
    _nome = nome;
    _descricao = descricao;
    _imagem = imagem;
    _preco = preco;
    _estoque = estoque;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Estufa && runtimeType == other.runtimeType && _nome == other._nome;

  @override
  int get hashCode => _nome.hashCode;
}
