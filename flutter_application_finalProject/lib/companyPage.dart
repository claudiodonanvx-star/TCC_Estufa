import 'package:flutter/material.dart';

class CompanyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      appBar: AppBar(
        title: Text('Conheça a Empresa', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green[300], // Cor do seu TCC
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            SizedBox(height: 20),
            _buildStorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.business, size: 36, color: Colors.green[700]),
        SizedBox(width: 10),
        Text(
          'Estufa Smart',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStorySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '📖 Nossa História',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A Estufa Smart nasceu da determinação de quatro amigos que compartilhavam uma visão: transformar a automação de processos agrícolas em uma solução acessível e eficiente. Durante os anos de estudo na COTIL - UNICAMP, eles identificaram desafios enfrentados por produtores na floricultura e decidiram criar uma estufa autorreguladora capaz de monitorar e ajustar automaticamente fatores como temperatura e umidade.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 8),
            Text(
              'Combinando tecnologia e inovação, o grupo desenvolveu um sistema baseado em sensores e automação para garantir um ambiente ideal de cultivo. A ideia rapidamente ganhou força, despertando interesse na comunidade agrícola e abrindo portas para novas oportunidades. Hoje, a Estufa Smart representa um avanço na forma como pequenos e médios produtores podem otimizar seus cultivos, trazendo sustentabilidade e eficiência para o setor.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
