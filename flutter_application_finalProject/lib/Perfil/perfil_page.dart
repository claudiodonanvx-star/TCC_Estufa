import 'package:flutter/material.dart';
import 'package:flutter_application_1/cadastro/cliente.dart';
import 'cliente_service.dart';
import 'editar_cliente_page.dart';

class PerfilPage extends StatefulWidget {
  final String cpfLogado;
  final bool administrador;
  final ValueChanged<int>? onPendenciasAtualizadas;

  const PerfilPage({
    super.key,
    this.cpfLogado = '',
    this.administrador = false,
    this.onPendenciasAtualizadas,
  });

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  List<Cliente> clientes = [];
  List<ClientePendenteDto> pendentes = [];
  Cliente? meuPerfil;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarClientes();
  }

  Future<void> carregarClientes() async {
    if (widget.administrador) {
      final lista = await ClienteService.buscarClientes();
      final listaPendentes = await ClienteService.buscarPendentes(widget.cpfLogado);
      final quantidade = await ClienteService.quantidadePendentes(widget.cpfLogado);
      widget.onPendenciasAtualizadas?.call(quantidade);

      setState(() {
        clientes = lista;
        pendentes = listaPendentes;
        carregando = false;
      });
      return;
    }

    final perfil = await ClienteService.buscarClientePorCpf(widget.cpfLogado);
    setState(() {
      meuPerfil = perfil;
      carregando = false;
    });
  }

  void abrirEdicao(Cliente cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EditarClientePage(
              cliente: cliente,
              requesterCpf: widget.cpfLogado,
              administradorLogado: widget.administrador,
            ),
      ),
    ).then((_) => carregarClientes());
  }

  Future<void> aprovarRegistro(ClientePendenteDto registro) async {
    final sucesso = await ClienteService.aprovarPendente(registro.id, widget.cpfLogado);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso ? 'Registro aprovado com sucesso.' : 'Não foi possível aprovar o registro.',
        ),
      ),
    );

    if (sucesso) {
      carregarClientes();
    }
  }

  Future<void> recusarRegistro(ClientePendenteDto registro) async {
    final motivoController = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Recusar registro'),
            content: TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo da recusa (opcional)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Recusar'),
              ),
            ],
          ),
    );

    if (confirmado != true) return;

    final sucesso = await ClienteService.recusarPendente(
      registro.id,
      widget.cpfLogado,
      motivo: motivoController.text,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso ? 'Registro recusado.' : 'Não foi possível recusar o registro.',
        ),
      ),
    );

    if (sucesso) {
      carregarClientes();
    }
  }

  Future<void> removerCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Remover cliente'),
            content: Text('Deseja remover ${cliente.nome}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Remover'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    final sucesso = await ClienteService.removerCliente(cliente.cpf, widget.cpfLogado);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso ? 'Cliente removido com sucesso.' : 'Falha ao remover cliente.',
        ),
      ),
    );

    if (sucesso) {
      carregarClientes();
    }
  }

  Widget _buildCardCliente(Cliente c, {bool permitirEdicao = true}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text(c.nome),
        subtitle: Text('${c.sexo} • ${c.cpf}${c.administrador ? ' • ADM' : ''}'),
        trailing:
            permitirEdicao
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => abrirEdicao(c),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => removerCliente(c),
                    ),
                  ],
                )
                : null,
      ),
    );
  }

  Widget _buildPendencias() {
    if (pendentes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Sem registros pendentes de validação.'),
      );
    }

    return Column(
      children:
          pendentes
              .map(
                (p) => Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text(p.nome),
                    subtitle: Text('${p.cpf} • ${p.email}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Aprovar',
                          onPressed: () => aprovarRegistro(p),
                          icon: Icon(Icons.check_circle, color: Colors.green),
                        ),
                        IconButton(
                          tooltip: 'Recusar',
                          onPressed: () => recusarRegistro(p),
                          icon: Icon(Icons.cancel, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.administrador ? 'Perfil (Administrador)' : 'Meu Perfil';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: carregando
          ? Center(child: CircularProgressIndicator())
          : widget.administrador
          ? RefreshIndicator(
            onRefresh: carregarClientes,
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  title: Text('Registros aguardando validação'),
                  subtitle: Text('${pendentes.length} pendente(s)'),
                ),
                _buildPendencias(),
                Divider(),
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text('Usuários habilitados'),
                ),
                ...clientes.map((c) => _buildCardCliente(c)),
              ],
            ),
          )
          : meuPerfil == null
          ? Center(
            child: Text('Perfil não encontrado para o usuário logado.'),
          )
          : ListView(
            children: [_buildCardCliente(meuPerfil!, permitirEdicao: false)],
          ),
    );
  }
}
