import 'package:flutter/material.dart';
import 'package:flutter_application_1/vendas/carrinho.dart';
import 'package:flutter_application_1/vendas/itemcarrinho.dart';
import 'package:flutter_application_1/marquee.dart';
import 'package:flutter_application_1/vendas/estufa.dart';

class ComprasEstufas extends StatefulWidget {
  const ComprasEstufas({super.key});

  @override
  State<ComprasEstufas> createState() => _ComprasEstufasState();
}

class _ComprasEstufasState extends State<ComprasEstufas> {
  List<Estufa> estufas = [];
  List<Estufa> estufasFiltradas = [];
  List<ItemCarrinho> carrinho = [];
  List<int> quantidades = [];
  List<Estufa> favoritos = [];
  bool mostrarSoFavoritos = false;
  String searchQuery = '';
  List<Estufa> estufasSugeridas = [];

  @override
  void initState() {
    super.initState();
    estufas = [
      Estufa(nome: 'Estufa Agrícola Premium', descricao: 'Mini Estufa Agrícola Premium para seu jardim, negócio ou projeto. Nela pode ser cultivado diversos tipo de cultivos, com: suculentas, orquídeas, hortaliças, temperos, mudas, flores, etc...', imagem: 'assets/images/estufa1.png', preco: 53827.34, estoque: 3),
      Estufa(nome: 'Mini Estufa 3x5', descricao: 'Estufa 4 camadas com tampa de PVC pequenas prateleiras de plá stico para cultivo de casa e jardim externo.', imagem: 'assets/images/estufa2.jpg', preco: 5076.82, estoque: 5),
      Estufa(nome: 'Estufa Modelo 7x22', descricao: 'Estufa de PVC de alta qualidade, resistente à corrosão e durável, com um tamanho de 7x22. Proteção à prova dágua e UV, deixe suas plantas e flores absorverem mais luz solar suficiente e forneça espaço suficiente para que suas plantas cresçam.', imagem: 'assets/images/estufa3.jpg', preco: 4596.23, estoque: 2),
      Estufa(nome: 'Estufa Econômica', descricao: 'Estrutura completa e com o tamanho compacto de 2m por 3m, contando com irrigação localizada e automatizada para maior facilidade do manejo, iluminação do ambiente, e sistema exclusivo de canteiros verticais, sendo 12 calhas para os canteiros, todas fabricadas em alumínio. Modelo totalmente projetado e estruturado para um baixo consumo de água e energia.', imagem: 'assets/images/estufa4.png', preco: 9000.00, estoque: 4),
      Estufa(nome: 'Estufa Luxo', descricao: 'Estufa de Luxo no tamanho de 4,00x9,00 metros é ideal para residencias e mini cultivos. Ideal para cultivo de hidroponia, hortifruti, suculentas, flores e plantas.', imagem: 'assets/images/estufa13.jpg', preco: 70000.00, estoque: 2),
      Estufa(nome: 'Estufa Agrícola', descricao: 'Estufa Agrícola 6x3m, Retém o calor, mantendo o ambiente mais ameno, ideal para melhor desenvolvimento de frutas, vegetais e outras Hortas mesmo fora de época.', imagem: 'assets/images/estufa6.jpg', preco: 40856.95, estoque: 6),
      Estufa(nome: 'Estufa Modular', descricao: 'A estrutura geodésica desta estufa facilita sua ótima e constante orientação ao sol, alias de sua elevada resistência às cargas como vento ou estruturas penduradas no interior. Combinado com o sistema solar passivo devido a sua orientação constante ao sol e homogênea ventilação, oferece possibilidades ótimas de obter produções boas nos cultivos.', imagem: 'assets/images/estufa7.jpg', preco: 12000.00, estoque: 3),
      Estufa(nome: 'Estufas de Jardim', descricao: 'Compacta e funcional, ideal para cultivo de flores e hortaliças no quintal, mantendo o ambiente protegido e bem iluminado.', imagem: 'assets/images/estufa8.jpg', preco: 7600.00, estoque: 2),
      Estufa(nome: 'Estufa Profissional', descricao: 'Estufa profissional com estrutura reforçada e cobertura anti-UV, ideal para produção em larga escala com alto controle climático.', imagem: 'assets/images/estufa9.jpg', preco: 120000.00, estoque: 1),
      Estufa(nome: 'Estufa de Madeira', descricao: 'Estufa de madeira com design rústico e aconchegante, ideal para hortas caseiras, garantindo boa ventilação e isolamento térmico.', imagem: 'assets/images/estufa10.jpg', preco: 8000.00, estoque: 7),
      Estufa(nome: 'Estufa Básica', descricao: 'Estufa pequena, fácei de mover 70 x 49 x 92 cm à prova dágua e material de PVC antiUV estufa portátil para ambientes internos e externos para sementes e mudas.', imagem: 'assets/images/estufa11.jpg', preco: 1000.00, estoque: 4),
      Estufa(nome: 'Estufa Doméstica', descricao: 'Estufa pequena UV do passatempo 6x8 do policarbonato de Sunor.', imagem: 'assets/images/estufa12.jpg', preco: 2256.60, estoque: 5),
      Estufa(nome: 'Estufa Agrícola 2', descricao: 'Esta estrutura metálica de aço galvanizado tem 4,00m de largura por 3,00m de comprimento e 2,20m no pé direito. A área total da estrutura é 12,00 m2 e contará com tubos 30x40 na lateral. Além disso terá uma cobertura filme difusor 150 micras para proteger contra intempéries climaticas. O perímetro será revestido em tela monofilamento preta para maior segurança do local. Por fim haverá um portão de abrir 1,00 x 2,10m para acesso às instalações internas.', imagem: 'assets/images/estufa5.jpg', preco:  17670.40, estoque: 6),
      Estufa(nome: 'Estufa de Parede', descricao: 'Compacta e prática, perfeita para espaços pequenos. Ideal para cultivo vertical em varandas ou muros ensolarados.', imagem: 'assets/images/estufa14.jpg', preco: 9000.00, estoque: 3),
      Estufa(nome: 'Estufa Básica 2', descricao: 'Mini estufa de 4 camadas, estrutura de aço de 101,6 x 45,7 x 160 cm e cobertura de PE suporte de plástico para plantas Green House com tapete de repotting de plantas para uso interno.', imagem: 'assets/images/estufa15.jpg', preco: 3500.00, estoque: 7),
      Estufa(nome: 'Estufa de Vidro Básica', descricao: 'Design simples com estrutura em vidro, oferece boa luminosidade e proteção ideal para hortas pequenas e iniciantes.', imagem: 'assets/images/estufa16.jpg', preco: 11000.00, estoque: 8),
      Estufa(nome: 'Estufa Para Horta', descricao: 'Estufa ideal para hortas caseiras, protege suas plantas contra vento, chuva e pragas, mantendo o ambiente ideal para o cultivo saudável.', imagem: 'assets/images/estufa17.jpg', preco: 10600.00, estoque: 5),
      Estufa(nome: 'Estufa Doméstica 2', descricao: 'Estufa 2x0,77X1,9m(H) com área de 1,54m2 e com uma estrutura contendo tubo galvanizado 25x0,9mm, Plástico impermeável com estrutura reforçada com 210g/m2, com tratamento anti-UV 5%, 2 janelas de ventilação equipadas com rede mosquiteira e 1 porta larga de acesso',imagem: 'assets/images/estufa18.jpg', preco: 7600.00, estoque: 6),
      Estufa(nome: 'Estufa de Jardim 2', descricao: 'Estufa de jardim Tipo de túnel com 8 janelas e tampa de polietileno 600x300x200 cm Branco', imagem: 'assets/images/estufa19.jpg', preco: 8400.00, estoque: 4),
      Estufa(nome: 'Estufa Profissional 2', descricao: 'Modelo avançado para cultivo intensivo, com sistema automatizado de irrigação e ventilação, focado em eficiência e rendimento.', imagem: 'assets/images/estufa20.jpg', preco: 153080.99, estoque: 7),
      Estufa(nome: 'Estufa de Vidro', descricao: 'Estufa de vidro elegante e resistente, oferece excelente entrada de luz natural e controle climático ideal para o cultivo durante o ano todo.', imagem: 'assets/images/estufa21.jpg', preco: 100000.00, estoque: 8),
    ];
    estufasFiltradas = List.from(estufas);
    quantidades = List<int>.filled(estufas.length, 1);
    atualizarEstufasSugeridas();
  }

  void atualizarEstufasSugeridas() {
    final estufasNoCarrinho = carrinho.map((e) => e.estufa).toSet();
    estufasSugeridas = estufas.where((e) => !estufasNoCarrinho.contains(e)).toList();
  }

  void filtrarEstufas() {
    setState(() {
      List<Estufa> lista = estufas;
      if (mostrarSoFavoritos) {
        lista = lista.where((e) => favoritos.contains(e)).toList();
      }
      if (searchQuery.isNotEmpty) {
        lista = lista.where((e) => e.nome.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }
      estufasFiltradas = lista;
    });
  }

  void adicionarAoCarrinho(Estufa estufa, int quantidade) {
    if (estufa.estoque >= quantidade) {
      setState(() {
        var item = carrinho.firstWhere(
          (element) => element.estufa == estufa,
          orElse: () => ItemCarrinho(estufa: estufa, quantidade: 0),
        );
        if (item.quantidade == 0) {
          carrinho.add(ItemCarrinho(estufa: estufa, quantidade: quantidade));
        } else {
          item.quantidade += quantidade;
        }
        estufa.estoque -= quantidade;
        atualizarEstufasSugeridas();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estoque insuficiente!')),
      );
    }
  }

  void removerDoCarrinho(Estufa estufa) {
    setState(() {
      final item = carrinho.firstWhere((element) => element.estufa == estufa);
      if (item.quantidade > 1) {
        item.quantidade--;
      } else {
        carrinho.remove(item);
      }
      estufa.estoque++;
      atualizarEstufasSugeridas();
    });
  }

  void finalizarCompra() {
    setState(() {
      carrinho.clear();
      atualizarEstufasSugeridas();
    });
  }

  void toggleFavorito(Estufa estufa) {
    setState(() {
      if (favoritos.contains(estufa)) {
        favoritos.remove(estufa);
      } else {
        favoritos.add(estufa);
      }
      filtrarEstufas();
    });
  }

  void atualizarFavoritos(Estufa estufa) {
    setState(() {
      if (favoritos.contains(estufa)) {
        favoritos.remove(estufa);
      } else {
        favoritos.add(estufa);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 20,
          child: Marquee(
            text: '🔖 Pagamento no Pix    •    💳 Em até 10X sem juros no cartão    •    🚚 Envio para todo o Brasil',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            scrollAxis: Axis.horizontal,
            blankSpace: 50.0,
            velocity: 50.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        backgroundColor: Colors.green[300],
      ),
      backgroundColor: const Color.fromARGB(255, 238, 253, 238),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Image.asset(
                    'assets/imagesE/logo_colorido.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                      minWidth: 300,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar estufas...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      style: const TextStyle(fontSize: 18),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          filtrarEstufas();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    mostrarSoFavoritos ? Icons.favorite : Icons.favorite_border,
                    color: mostrarSoFavoritos ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      mostrarSoFavoritos = !mostrarSoFavoritos;
                      filtrarEstufas();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarrinhoPage(
                          carrinho: carrinho,
                          removerDoCarrinho: removerDoCarrinho,
                          finalizarCompra: finalizarCompra,
                          estufasSugeridas: estufasSugeridas,
                          favoritos: favoritos,
                          toggleFavorito: atualizarFavoritos,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(thickness: 2, color: Colors.black),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: estufasFiltradas.length,
              itemBuilder: (context, index) {
                final estufa = estufasFiltradas[index];
                final originalIndex = estufas.indexOf(estufa);
                final isFavorito = favoritos.contains(estufa);

                return Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet( 
  context: context,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          estufa.nome,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          child: Text(estufa.descricao),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[300],
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    ),
  ),
);

                                },
                                child: Image.asset(estufa.imagem, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  toggleFavorito(estufa);
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
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          estufa.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Text('R\$${estufa.preco.toStringAsFixed(2)}'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (quantidades[originalIndex] > 1) {
                                  quantidades[originalIndex]--;
                                }
                              });
                            },
                          ),
                          Text('${quantidades[originalIndex]}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                if (quantidades[originalIndex] < estufa.estoque) {
                                  quantidades[originalIndex]++;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.green[200],
                             foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                             textStyle: const TextStyle(
                             fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: estufa.estoque >= quantidades[originalIndex]
                            ? () {
                                adicionarAoCarrinho(estufa, quantidades[originalIndex]);
                              }
                            : null,
                        child: const Text('Adicionar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
