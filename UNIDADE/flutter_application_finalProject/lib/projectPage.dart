import 'package:flutter/material.dart';

class ProjectPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      appBar: AppBar(
        title: Text('Conheça Nosso Projeto', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green[300],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSection(),
            SizedBox(height: 20),
            _buildTechnologySection(),
            SizedBox(height: 20),
            _buildBenefitsSection(),
            SizedBox(height: 20),
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌿 Estufa Smart – Implementação de estufas autônomas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A crescente demanda por soluções sustentáveis na floricultura tem impulsionado novas tecnologias para otimizar o cultivo em ambientes controlados.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnologySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🛠 Tecnologia Utilizada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '✔ Sensores de umidade e temperatura\n'
              '✔ CLP para gerenciamento\n'
              '✔ Controle remoto via aplicativo\n'
              '✔ Câmera para monitoramento',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Benefícios para o usuário',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '✔ Proteção contra clima extremo\n'
              '✔ Cultivo o ano todo\n'
              '✔ Controle de pragas sem pesticidas\n'
              '✔ Eficiência energética',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/imagesC/estufa_smart.jpg',
            height: 200, fit: BoxFit.cover),
      ),
    );
  }
}
