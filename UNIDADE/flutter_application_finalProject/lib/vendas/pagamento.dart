import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/main.dart';
import 'itemcarrinho.dart';
import 'resumo.dart';

class PagamentoPage extends StatefulWidget {
  final List<ItemCarrinho> carrinho;
  final VoidCallback finalizarCompra;
  final Function removerDoCarrinho;

  const PagamentoPage({
    super.key,
    required this.carrinho,
    required this.finalizarCompra,
    required this.removerDoCarrinho,
  });

  @override
  State<PagamentoPage> createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  String metodoPagamento = 'pix';
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController validadeController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  int parcelas = 1;

  List<Map<String, dynamic>> opcoesFrete = [];
  String? freteSelecionado;

  double get totalProdutos =>
      widget.carrinho.fold(0.0, (soma, item) => soma + item.estufa.preco * item.quantidade);

  @override
  void initState() {
    super.initState();
    opcoesFrete = [
      {"tipo": "Entrega Padrão", "valor": Random().nextDouble() * (100 - 20) + 20},
      {"tipo": "Entrega via Sedex", "valor": Random().nextDouble() * (200 - 100) + 100},
      {"tipo": "Retire no local", "valor": 0.0},
    ];
  }

  String? _validarCartao() {
    String numeroCartao = numeroController.text.replaceAll(" ", "");
    if (numeroCartao.length != 16) return "O número do cartão deve ter 16 dígitos.";
    if (codigoController.text.length != 3) return "O código de segurança deve ter 3 dígitos.";
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(validadeController.text)) return "A validade deve estar no formato MM/AA.";
    if (nomeController.text.isEmpty || RegExp(r'\d').hasMatch(nomeController.text)) {
      return "O nome do titular não pode conter números e não pode ser vazio.";
    }
    return null;
  }

  void _formatarNumeroCartao(String texto) {
    String textoFormatado = texto.replaceAll(RegExp(r'\D'), '');
    if (textoFormatado.length > 16) textoFormatado = textoFormatado.substring(0, 16);
    String numeroFormatado = '';
    for (int i = 0; i < textoFormatado.length; i++) {
      if (i > 0 && i % 4 == 0) numeroFormatado += ' ';
      numeroFormatado += textoFormatado[i];
    }
    numeroController.text = numeroFormatado;
    numeroController.selection = TextSelection.collapsed(offset: numeroFormatado.length);
  }

  void _formatarValidade(String texto) {
    String v = texto.replaceAll(RegExp(r'\D'), '');
    if (v.length > 4) v = v.substring(0, 4);
    if (v.length > 2) v = '${v.substring(0, 2)}/${v.substring(2, 4)}';
    validadeController.text = v;
    validadeController.selection = TextSelection.collapsed(offset: v.length);
  }

  double get valorFreteSelecionado {
    if (freteSelecionado == null) return 0.0;
    return opcoesFrete.firstWhere((f) => f['tipo'] == freteSelecionado)['valor'];
  }

  double get totalPago => totalProdutos + valorFreteSelecionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
        backgroundColor: const Color.fromARGB(255, 129, 199, 132),
      ),
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.carrinho.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var item in widget.carrinho)
                        Column(
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  item.estufa.imagem,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.estufa.nome,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Preço: R\$${item.estufa.preco.toStringAsFixed(2)}'),
                                    Text('Quantidade: ${item.quantidade}'),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'Total: R\$${(item.estufa.preco * item.quantidade).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                          ],
                        ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Opção de Envio:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ExpansionTile(
                        title: Row(
                          children: const [
                            Icon(Icons.local_shipping, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Ver mais'),
                          ],
                        ),
                        children: [
                          for (var frete in opcoesFrete)
                            ListTile(
                              title: Row(
                                children: [
                                  Text(frete['tipo']),
                                  const Spacer(),
                                  Text('R\$${frete['valor'].toStringAsFixed(2)}'),
                                ],
                              ),
                              trailing: Radio<String>(
                                value: frete['tipo'],
                                groupValue: freteSelecionado,
                                onChanged: (String? value) {
                                  setState(() {
                                    freteSelecionado = value;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Divider(thickness: 2, color: Colors.black),
              const SizedBox(height: 20),
              const Text(
                'Selecione o método de pagamento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: Row(
                  children: const [
                    Icon(Icons.monetization_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Pix'),
                  ],
                ),
                leading: Radio<String>(
                  value: 'pix',
                  groupValue: metodoPagamento,
                  onChanged: (v) {
                    setState(() {
                      metodoPagamento = v!;
                      parcelas = 1;
                    });
                  },
                ),
              ),
              ListTile(
                title: Row(
                  children: const [
                    Icon(Icons.wallet_travel, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Cartão de Crédito'),
                  ],
                ),
                leading: Radio<String>(
                  value: 'cartao',
                  groupValue: metodoPagamento,
                  onChanged: (v) {
                    setState(() {
                      metodoPagamento = v!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              if (metodoPagamento == 'pix')
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Código Pix:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                '00020126580014BR.GOV.BCB.PIX0114+556199999999520400005303986540410005802BR5925Empresa de Estufas6009Brasilia62070503***6304ABCD',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.green),
              onPressed: () {
                Clipboard.setData(const ClipboardData(
                  text: '00020126580014BR.GOV.BCB.PIX0114+556199999999520400005303986540410005802BR5925Empresa de Estufas6009Brasilia62070503***6304ABCD',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(                   
                    backgroundColor: Colors.green[300],
                    content: const Text('Código Pix copiado!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ],
  ),
              if (metodoPagamento == 'cartao')
                Column(
                  children: [
                    TextField(
                      controller: numeroController,
                      decoration: const InputDecoration(
                        labelText: 'Número do Cartão',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(19),
                      ],
                      onChanged: _formatarNumeroCartao,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Titular',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z ]'))],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: validadeController,
                      decoration: const InputDecoration(
                        labelText: 'Validade (MM/AA)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onChanged: _formatarValidade,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codigoController,
                      decoration: const InputDecoration(
                        labelText: 'Código de Segurança',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Parcelamento:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ExpansionTile(
  title: Row(
    children: [
      const Icon(Icons.payment, color: Colors.purple),
      const SizedBox(width: 8),
      Text('Parcelamento: $parcelas x sem juros'),
    ],
  ),
  children: [
    for (int i = 1; i <= 10; i++)
      ListTile(
        title: Text('$i x de R\$${(totalPago / i).toStringAsFixed(2)}'),
        trailing: Radio<int>(
          value: i,
          groupValue: parcelas,
          onChanged: (int? value) {
            setState(() {
              parcelas = value!;
            });
          },
        ),
      ),
  ],
),
                  ],
                ),
              Divider(thickness: 2, color: Colors.black),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalhe do Pagamento',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total do Produto:'),
                        Text('R\$${totalProdutos.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total do Frete:'),
                        Text('R\$${valorFreteSelecionado.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pagamento Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$${totalPago.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (metodoPagamento == 'cartao') {
                    final validacao = _validarCartao();
                    if (validacao != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validacao)));
                      return;
                    }
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AlertDialog(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 40),
                          SizedBox(width: 16),
                          Expanded(child: Text('Compra finalizada com sucesso!')),
                        ],
                      ),
                    ),
                  );

                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          content: ResumoCompra(
                            itensCarrinho: widget.carrinho,
                            valorFrete: valorFreteSelecionado,
                            metodoPagamento: metodoPagamento == 'pix' ? 'Pix' : 'Cartão de Crédito',
                            parcelas: metodoPagamento == 'cartao' ? parcelas : 1,
                          valorParcela: metodoPagamento == 'cartao'
                          ? (totalPago / parcelas)
                          : totalPago,
),
                          actions: [
                            TextButton(
                              onPressed: () {
                                 widget.finalizarCompra();
                                 Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()), // Retorna à HomePage
                );
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  });
                },
                child: const Text('Confirmar Pagamento'),
                
              ),
            ],
          ),
        ),
      ),
    );
  }
}
