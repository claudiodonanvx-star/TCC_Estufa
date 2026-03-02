import 'package:flutter/material.dart';
import 'itemcarrinho.dart';

class ResumoCompra extends StatelessWidget {
  final List<ItemCarrinho> itensCarrinho;
  final double valorFrete;
  final String metodoPagamento;
  final int parcelas;
  final double? valorParcela; // NOVO

  const ResumoCompra({
    Key? key,
    required this.itensCarrinho,
    required this.valorFrete,
    required this.metodoPagamento,
    required this.parcelas,
    this.valorParcela, // NOVO
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalProdutos = itensCarrinho.fold(
      0.0, (soma, item) => soma + item.estufa.preco * item.quantidade);
    double total = totalProdutos + valorFrete;

    return Align(
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width < 600 
          ? double.infinity // em telas pequenas (celular) ocupa toda a largura
          : MediaQuery.of(context).size.width * 0.25, // em telas grandes fica limitado
    ),
    child: SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 238, 253, 238),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromARGB(255, 129, 199, 132),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ALINHA OS TEXTOS À ESQUERDA
          children: [
            Text(
              'Resumo da Compra',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color.fromARGB(255, 129, 199, 132),
              ),
            ),
            const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Método de Pagamento:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(metodoPagamento, style: const TextStyle(fontSize: 16)),
                    ],
                  ),

                  if (metodoPagamento.toLowerCase() == 'cartão de crédito') ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Parcelamento:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${parcelas}x de R\$${valorParcela?.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  ...itensCarrinho.map((item) {
                    double valorItem = item.estufa.preco * item.quantidade;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              item.estufa.imagem,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.estufa.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            Text('x${item.quantidade}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Valor do Produto:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('R\$${valorItem.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),

                  const Divider(height: 24, thickness: 1),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor do Frete:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('R\$${valorFrete.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),

                  const Divider(height: 24, thickness: 1),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('R\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
