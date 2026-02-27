import 'package:flutter/material.dart';

class PartnershipsPage extends StatelessWidget {
  const PartnershipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      appBar: AppBar(title: const Text('Nossas Parcerias Estratégicas', style: TextStyle(fontWeight: FontWeight.bold),), 
      backgroundColor: Colors.green[300]),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('🌿 Estufa Smart - Impacto e Parcerias'),
              const Text(
                'Nosso projeto une inovação e sustentabilidade para transformar a agricultura. '
                'Com tecnologia avançada, eliminamos o uso de agrotóxicos e garantimos um cultivo saudável.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('🔗 Empresas Parceiras'),
              SizedBox(
                height: 170,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHorizontalCard(
                        'Metaflon Agrotech',
                        'Especialistas em desenvolvimento de estufas agrícolas inteligentes.',
                      ),
                      _buildHorizontalCard(
                        'Syngenta Global AG',
                        'Tecnologia avançada em proteção de culturas e sementes para agricultores.',
                      ),
                      _buildHorizontalCard(
                        'Dow',
                        'Inovação química e biológica aplicada ao agronegócio sustentável.',
                      ),
                      _buildHorizontalCard(
                        'Abrafrutas',
                        'Expansão das frutas brasileiras no mercado global, promovendo sustentabilidade.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('🌸 Feiras e Eventos'),
              _buildPartnerInfo(
                'Global Produce & Floral Show',
                'Conectamos nossa tecnologia a produtores, mostrando inovação no cultivo de flores e frutas.',
              ),
              _buildPartnerInfo(
                'Irrigaflora',
                'Sistemas avançados de irrigação para otimizar o cultivo nas estufas.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('🏆 Prêmio Estufa Sustentável'),
              _buildAwardInfo(),
              const SizedBox(height: 20),

              _buildSectionTitle('✨ Por que escolher a Estufa Smart?'),
              _buildBenefits(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildPartnerInfo(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(String name, String description) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAwardInfo() {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '🏆 Prêmio Estufa Sustentável',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Nosso projeto foi reconhecido por sua inovação no cultivo sustentável. '
              'Eliminamos a necessidade de agrotóxicos e promovemos uma agricultura mais ecológica!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Column(
      children: [
        _buildBenefitItem('✅ Cultivo sem agrotóxicos, saudável e sustentável'),
        _buildBenefitItem('✅ Monitoramento inteligente para máxima eficiência'),
        _buildBenefitItem('✅ Parcerias estratégicas com líderes do setor'),
        _buildBenefitItem('✅ Inovação tecnológica para agricultura ecológica'),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
