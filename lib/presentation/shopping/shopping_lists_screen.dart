import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/model/lista_compras.dart';
import '../../domain/usecase/lista_compras_usecases.dart' as usecase;
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';

final listasComprasStreamProvider = StreamProvider<List<ListaCompras>>((ref) {
  return ref.watch(listaComprasRepositoryProvider).getAllListas();
});

class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listasAsync = ref.watch(listasComprasStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Listas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: yellowSecondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Lista'),
      ),
      body: listasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purplePrimary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (listas) {
          if (listas.isEmpty) {
            return const EmptyState(
              icon: Icons.list_outlined,
              title: 'Nenhuma lista criada',
              subtitle: 'Crie sua primeira lista para começar a registrar compras',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            itemCount: listas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ListaComprasItem(
              lista: listas[i],
              onTap: () => context.push('/shopping-lists/${listas[i].id}'),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: const Icon(Icons.add),
          title: const Text('Nova lista de compras'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
              hintText: 'Ex: Mercado - Semana 33',
            ),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () async {
                      final id = await usecase.createListaCompras(
                        ref.read(listaComprasRepositoryProvider),
                        controller.text,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        context.push('/shopping-lists/$id');
                      }
                    },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaComprasItem extends StatelessWidget {
  const _ListaComprasItem({required this.lista, required this.onTap});
  final ListaCompras lista;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFinalized = lista.status == StatusLista.finalizada;
    final cor = isFinalized ? successGreen : purplePrimary;
    final formatter = DateFormat('dd/MM/yyyy');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: isFinalized ? 0.12 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFinalized ? Icons.check_circle : Icons.shopping_cart,
                  color: cor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lista.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formatter.format(lista.dataCriacao),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lista.totalGasto > 0)
                    Text(
                      'R\$ ${formatarMoeda(lista.totalGasto)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cor,
                          ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: isFinalized ? 0.12 : 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isFinalized ? 'Finalizada' : 'Aberta',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
