import 'package:flutter/material.dart';
import 'package:flutter_application_1/vendas/estufa.dart';
import 'itemcarrinho.dart';
import 'pagamento.dart';

class CarrinhoPage extends StatefulWidget {
  final List<ItemCarrinho> carrinho;
  final Function removerDoCarrinho;
  final VoidCallback finalizarCompra;
  final List<Estufa> estufasSugeridas;
  final List<Estufa> favoritos;
  final Function(Estufa) toggleFavorito;

  const CarrinhoPage({
    required this.carrinho,
    required this.removerDoCarrinho,
    required this.finalizarCompra,
    required this.estufasSugeridas,
    required this.favoritos,
    required this.toggleFavorito,
    super.key,
  });

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  late List<ItemCarrinho> carrinhoLocal;
  late List<int> quantidadesSugeridas;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      carrinhoLocal = List.from(widget.carrinho);
      quantidadesSugeridas = List.filled(widget.estufasSugeridas.length, 1);
    });
  }

  void removerItem(Estufa estufa) {
    setState(() {
      carrinhoLocal.removeWhere((item) => item.estufa == estufa);
    });
    widget.removerDoCarrinho(estufa);
  }

  void adicionarAoCarrinho(Estufa estufa, int quantidade) {
    setState(() {
      final index = carrinhoLocal.indexWhere((item) => item.estufa == estufa);
      if (index == -1) {
        carrinhoLocal.add(ItemCarrinho(estufa: estufa, quantidade: quantidade));
      } else {
        carrinhoLocal[index].quantidade += quantidade;
      }
    });
  }

  double calcularTotal() {
    return carrinhoLocal.fold(
      0,
      (total, item) => total + item.estufa.preco * item.quantidade,
    );
  }

  void mostrarDescricaoEstufa(Estufa estufa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estufa.nome),
        content: Text(estufa.descricao),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estufasNoCarrinho = carrinhoLocal.map((item) => item.estufa).toSet();
    final estufasFiltradas = widget.estufasSugeridas
        .where((e) => !estufasNoCarrinho.contains(e))
        .take(14)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        backgroundColor: Colors.green[300],
      ),
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      body: SingleChildScrollView(
        child: Column(
          children: [
            carrinhoLocal.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Carrinho vazio'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: carrinhoLocal.length,
                    itemBuilder: (context, index) {
                      final item = carrinhoLocal[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                item.estufa.imagem,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(item.estufa.nome),
                            subtitle: Text(
                              '${item.quantidade} x R\$ ${item.estufa.preco.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    widget.favoritos.contains(item.estufa)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: widget.favoritos.contains(item.estufa)
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                  onPressed: () {
                                    widget.toggleFavorito(item.estufa);
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => removerItem(item.estufa),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            if (estufasFiltradas.isNotEmpty) ...[
              const Divider(thickness: 2, indent: 16, endIndent: 16, color: Colors.black),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Você também pode gostar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: estufasFiltradas.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final estufa = estufasFiltradas[index];
                  final isFavorito = widget.favoritos.contains(estufa);

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => mostrarDescricaoEstufa(estufa),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.asset(
                                  estufa.imagem,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  widget.toggleFavorito(estufa);
                                  setState(() {});
                                },
                                child: Icon(
                                  isFavorito ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorito ? Colors.red : Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(estufa.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${estufa.preco.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: quantidadesSugeridas[index] > 1
                                        ? () {
                                            setState(() {
                                              quantidadesSugeridas[index]--;
                                            });
                                          }
                                        : null,
                                  ),
                                  Text('${quantidadesSugeridas[index]}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        quantidadesSugeridas[index]++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[300],
                                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                                  textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                  shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () => adicionarAoCarrinho(estufa, quantidadesSugeridas[index]),
                                child: const Text('Adicionar'),
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            const Divider(thickness: 2, color: Colors.black),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Total: R\$ ${calcularTotal().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (carrinhoLocal.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Carrinho vazio!',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.green[100],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PagamentoPage(
                              carrinho: carrinhoLocal,
                              removerDoCarrinho: widget.removerDoCarrinho,
                              finalizarCompra: widget.finalizarCompra,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[300],
                    foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                    textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                    child: const Text('Ir para Pagamento'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
