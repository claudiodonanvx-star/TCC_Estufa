class Cliente {
  String nome;
  String usuario;
  String telefone;
  String email;
  String cpf;
  String sexo;
  String senha;
  String cep;
  String cidade;
  String bairro;
  String numero;
  String complemento;
  bool ativo;
  bool aceitouTermos;
  bool administrador;


  Cliente({
    required this.nome,
    this.usuario = '',
    required this.telefone,
    required this.email,
    required this.cpf,
    required this.sexo,
    required this.senha,
    required this.cep,
    required this.cidade,
    required this.bairro,
    required this.numero,
    required this.complemento,
    required this.ativo,
    required this.aceitouTermos,
    this.administrador = false,

  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      nome: json['nome'] ?? '',
      usuario: json['usuario'] ?? json['login'] ?? '',
      telefone: json['telefone'] ?? '',
      email: json['email'] ?? '',
      cpf: json['cpf'] ?? '',
      sexo: json['sexo'] ?? '',
      senha: json['senha'] ?? '',
      cep: json['cep'] ?? '',
      cidade: json['cidade'] ?? '',
      bairro: json['bairro'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'] ?? '',
      ativo: json['ativo'] ?? false,
      aceitouTermos: json['aceitouTermos'] ?? false,
      administrador: json['administrador'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      "nome": nome,
      "usuario": usuario,
      "telefone": telefone,
      "email": email,
      "cpf": cpf,
      "sexo": sexo,
      "senha": senha,
      "ativo": ativo,
      "aceitouTermos": aceitouTermos,
      "cep": cep,
      "cidade": cidade,
      "bairro": bairro,
      "numero": numero,
      "complemento": complemento,
      "administrador": administrador,
    };
  }

  Map<String, dynamic> toJsonCadastro() {
    return {
      "nome": nome,
      "usuario": usuario,
      "senha": senha,
    };
  }

  @override
  String toString() {
    return  'Nome: $nome\n'
            'Telefone: $telefone\n'
            'Email: $email\n'
            'CPF: $cpf\n'
            'Sexo: $sexo\n'
            'CEP: $cep\n'
            'Cidade: $cidade\n'
            'Bairro: $bairro\n'
            'Número: $numero\n'
            'Complemento: $complemento\n'
            'Ativo: ${ativo ? "Sim" : "Não"}\n'
            'AceitouTermos: ${aceitouTermos ? "Sim" : "Não"}\n';
  }
}
