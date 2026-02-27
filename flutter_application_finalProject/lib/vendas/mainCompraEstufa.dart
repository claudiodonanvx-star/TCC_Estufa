import 'package:flutter/material.dart';
import 'package:flutter_application_1/vendas/compras.dart';

class MainCompraEstufa extends StatelessWidget {
  const MainCompraEstufa({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ComprasEstufas(),
    );
  }
}