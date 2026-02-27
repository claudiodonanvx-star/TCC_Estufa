import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile.dart';
import 'package:flutter_application_1/profilePage.dart';

class ProfilesPage extends StatefulWidget {
  @override
  _ProfilesPageState createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final PageController _pageController = PageController();

  final List<Profile> profiles = [
    Profile(
      name: 'Claudio Eduardo Dona',
      about: 'Me chamo Claudio Eduardo Dona Filho, formado em Engenharia de Software, com especialização em Automação e Banco de Dados. Ao longo da minha trajetória, aprofundei meus conhecimentos em sistemas de gerenciamento de dados, otimização de consultas e segurança da informação, garantindo eficiência e confiabilidade para grandes volumes de dados.' + 
      '                                                                                                                        ' + 'Atualmente, atuo como DBA Senior (Database Administrator Senior), desempenhando um papel fundamental na administração, desempenho e integridade de bancos de dados. Com uma visão estratégica e foco na inovação, busco soluções tecnológicas que automatizam processos e potencializam a produtividade em diferentes setores. Minha experiência me permite unir performance e segurança, garantindo que sistemas críticos operem com eficiência e alta disponibilidade',
      imagePath: 'assets/imagesC/clau.jpg', 
    ),
    Profile(
      name: 'Daniely Toledo Vieira',
      about: 'Me chamo Daniely Toledo Vieira da Silva, sou Engenheira Agrônoma com especialização em Agricultura de Precisão e Sistemas Automatizados de Cultivo Protegido. Durante minha formação, aprofundei meus conhecimentos no uso de tecnologias como sensores climáticos, IoT, irrigação inteligente e automação voltada ao cultivo protegido, integrando inovação e sustentabilidade no campo. Essa trajetória técnica e empreendedora me levou a cofundar a EstufaSmart, onde atuo como CEO.',
      imagePath: 'assets/imagesC/dani.jpg', 
    ),
    Profile(
      name: 'Heloísa Caroline Xavier',
      about: 'Me chamo Heloísa Caroline Xavier Cavalcante, com formação em Engenharia Agronômica com especialização em Agricultura de Precisão e Sistemas Automatizados de Cultivo Protegido, onde me aprofundei no uso de tecnologias como sensores climáticos, IoT, irrigação controlada e automação aplicada ao cultivo protegido. Essa base técnica me permitiu unir inovação e sustentabilidade, criando soluções inteligentes para o agronegócio através da EstufaSmart. Sou uma das fundadora e CEO da EstufaSmart, uma empresa focada em inovação e tecnologia voltada para agricultura sustentável. Com espírito empreendedor e olhar atento às necessidades do produtor rural moderno, a ideia da EstufaSmart foi com o propósito de facilitar o acesso a estufas inteligentes, eficientes e acessíveis para pequenos, médios e grandes agricultores.',
      imagePath: 'assets/imagesC/helo.jpg', 
    ),
    Profile(
      name: 'Evelyn Cristina Santiago',
      about: 'Sou Evelyn Cristina, formada em Engenharia Agronômica com especialização em Agricultura de Precisão e Sistemas Automatizados de Cultivo Protegido. Durante minha formação, aprofundei-me no uso de tecnologias como sensores climáticos, IoT, irrigação controlada e automação aplicada ao cultivo protegido. Essa sólida base técnica me permitiu unir inovação e sustentabilidade, desenvolvendo soluções inteligentes para o agronegócio por meio da EstufaSmart. Como uma das fundadoras e CEO da EstufaSmart, estou dedicada a impulsionar a inovação e a tecnologia voltadas para a agricultura sustentável.',
      imagePath: 'assets/imagesC/evel.jpg', 
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        title: Text('Perfis', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return ProfilePage(profile: profiles[index]);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: 30,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.grey,
                    ),
                  ],
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward,
                  size: 30,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.grey,
                    ),
                  ],
                ),
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
