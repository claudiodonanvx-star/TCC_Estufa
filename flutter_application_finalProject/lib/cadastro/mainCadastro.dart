import 'package:flutter/material.dart';
import 'package:flutter_application_1/cadastro/telaInicial.dart';

class MainCadastro extends StatelessWidget {
  const MainCadastro({super.key});

 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
      
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Telainicial(),
    );
  }
}
