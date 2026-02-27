import 'package:flutter/material.dart';
import 'package:flutter_application_1/Perfil/perfil_page.dart';
import 'package:flutter_application_1/iot/TelaDados.dart';
import 'package:flutter_application_1/profilesPage.dart';
import 'package:flutter_application_1/projectPage.dart';
import 'package:flutter_application_1/companyPage.dart';
import 'package:flutter_application_1/partnershipsPage.dart';
import 'package:flutter_application_1/cadastro/mainCadastro.dart';
import 'package:flutter_application_1/vendas/mainCompraEstufa.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainCadastro(), // Agora inicia na tela de cadastro
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  final String cpfLogado;
  final bool administrador;
  final int pendenciasAprovacao;

  const HomePage({
    super.key,
    this.cpfLogado = '',
    this.administrador = false,
    this.pendenciasAprovacao = 0,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isMenuOpen = true; // Controla se o menu está aberto ou fechado
  late int _pendenciasAprovacao;
  Widget _currentScreen = MainCompraEstufa(); // Tela inicial

  @override
  void initState() {
    super.initState();
    _pendenciasAprovacao = widget.pendenciasAprovacao;
  }

  void _atualizarPendencias(int quantidade) {
    setState(() {
      _pendenciasAprovacao = quantidade;
    });
  }

  void _navigateTo(Widget screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menu lateral animado que abre e fecha
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _isMenuOpen ? 250 : 0, // Altera a largura dinamicamente
            color: Colors.green[700],
            child:
                _isMenuOpen
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(
                            'assets/imagesC/logo.png',
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildMenuItem(
                          Icons.shopping_cart,
                          'Compre Estufas',
                          MainCompraEstufa(),
                        ),
                        _buildMenuItem(
                          Icons.business,
                          'Conheça a Empresa',
                          CompanyPage(),
                        ),
                        _buildMenuItem(
                          Icons.people,
                          'Conheça os Desenvolvedores',
                          ProfilesPage(),
                        ),
                        _buildMenuItem(
                          Icons.auto_graph,
                          'Nosso Projeto',
                          ProjectPage(),
                        ),
                        _buildMenuItem(
                          Icons.event,
                          'Parceiros e Eventos',
                          PartnershipsPage(),
                        ),
                        _buildMenuItem(Icons.usb, 'IOT', TelaDados()),
                        _buildMenuItem(
                          Icons.people,
                          'Perfil',
                          PerfilPage(
                            cpfLogado: widget.cpfLogado,
                            administrador: widget.administrador,
                            onPendenciasAtualizadas: _atualizarPendencias,
                          ),
                          mostrarAlerta:
                              widget.administrador && _pendenciasAprovacao > 0,
                        ),
                      ],
                    )
                    : SizedBox(), // Esconde o menu quando fechado
          ),

          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                // Botão de abrir/fechar o menu
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
                    onPressed: _toggleMenu,
                  ),
                ),
                Expanded(
                  child: _currentScreen, // Exibe a página selecionada
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Widget page, {
    bool mostrarAlerta = false,
  }) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white),
          if (mostrarAlerta)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
      onTap: () => _navigateTo(page),
    );
  }
}
