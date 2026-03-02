class Usuario {
  static final Map<String, String> _usuarios = {
    'abc': '123',
  };

  static void adicionarUsuario(String login, String senha) {
    _usuarios[login] = senha;
  }

  static bool validarUsuario(String login, String senha) =>
      _usuarios[login] == senha;
      
}
