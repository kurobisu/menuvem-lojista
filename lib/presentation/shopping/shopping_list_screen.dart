import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/model/lista_compras.dart';
import '../../theme/app_theme.dart';
import '../components/back_or_home_button.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/responsive.dart';
import 'add_item_bottom_sheet.dart';
import 'item_lista_card.dart';
import 'shopping_list_controller.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key, required this.listaId});

  final int listaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(shoppingListDataProvider(listaId));
    final actions = ref.read(shoppingListActionsProvider(listaId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: dataAsync.maybeWhen(
          data: (d) => Text(d.lista?.nome ?? 'Lista de Compras'),
          orElse: () => const Text('Lista de Compras'),
        ),
      ),
      floatingActionButton: dataAsync.maybeWhen(
        data: (data) {
          if (data.lista?.status == StatusLista.finalizada) return null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.itensComprados > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'finish',
                    backgroundColor: successGreen,
                    foregroundColor: Colors.white,
                    onPressed: () => _showFinishDialog(
                      context,
                      ref,
                      actions,
                      data.itensComprados,
                    ),
                    child: const Icon(Icons.done),
                  ),
                ),
              FloatingActionButton(
                heroTag: 'add',
                backgroundColor: yellowSecondary,
                foregroundColor: Colors.white,
                onPressed: () => showResponsiveFormSheet<void>(
                  context,
                  builder: (_) => AddItemBottomSheet(
                    onAdd:
                        ({
                          required nomeItem,
                          required quantidade,
                          required unidade,
                          precoUnitario = 0.0,
                          insumo,
                        }) => actions.addItem(
                          nomeItem: nomeItem,
                          quantidade: quantidade,
                          unidade: unidade,
                          precoUnitario: precoUnitario,
                          insumo: insumo,
                        ),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          );
        },
        orElse: () => null,
      ),
      body: MaxWidthCenter(
        child: dataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: purplePrimary),
          ),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (data) {
            if (data.itens.isEmpty) {
              return const EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Lista vazia',
                subtitle: 'Toque em + para adicionar os primeiros itens',
              );
            }
            final pendentes = data.itens.where((i) => !i.comprado).toList();
            final comprados = data.itens.where((i) => i.comprado).toList();
            return Column(
              children: [
                _HeaderResumo(
                  lista: data.lista,
                  comprados: data.itensComprados,
                  total: data.totalItens,
                  totalGasto: data.totalGasto,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    children: [
                      if (pendentes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Text(
                            'A comprar (${pendentes.length})',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        ...pendentes.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ItemListaCard(
                              item: item,
                              tendencia: item.insumoId != null
                                  ? data.tendencias[item.insumoId]
                                  : null,
                              onToggle: (checked, preco) =>
                                  actions.toggleItem(item.id, checked, preco),
                              onDelete: () => actions.deleteItem(item),
                            ),
                          ),
                        ),
                      ],
                      if (comprados.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Text(
                            'Comprados (${comprados.length})',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        ...comprados.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ItemListaCard(
                              item: item,
                              tendencia: item.insumoId != null
                                  ? data.tendencias[item.insumoId]
                                  : null,
                              onToggle: (checked, preco) =>
                                  actions.toggleItem(item.id, checked, preco),
                              onDelete: () => actions.deleteItem(item),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingListActions actions,
    int itensComprados,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _FinishDialog(itensComprados: itensComprados, actions: actions),
    );
  }
}

class _FinishDialog extends StatefulWidget {
  const _FinishDialog({required this.itensComprados, required this.actions});
  final int itensComprados;
  final ShoppingListActions actions;

  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog> {
  bool _isFinishing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.shopping_bag),
      title: const Text('Finalizar compra?'),
      content: Text(
        'Os preços dos ${widget.itensComprados} itens comprados serão registrados e os '
        'insumos vinculados terão seus custos atualizados automaticamente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: successGreen),
          onPressed: _isFinishing
              ? null
              : () async {
                  setState(() => _isFinishing = true);
                  await widget.actions.finalizarCompra();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compra finalizada! Custos atualizados.'),
                      ),
                    );
                  }
                },
          child: _isFinishing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Finalizar'),
        ),
      ],
    );
  }
}

class _HeaderResumo extends StatelessWidget {
  const _HeaderResumo({
    required this.lista,
    required this.comprados,
    required this.total,
    required this.totalGasto,
  });
  final ListaCompras? lista;
  final int comprados;
  final int total;
  final double totalGasto;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? comprados / total : 0.0;
    final formatter = DateFormat('dd/MM/yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [purplePrimary, purplePrimary.withValues(alpha: 0.85)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lista != null)
            Text(
              formatter.format(lista!.dataCriacao),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          if (lista?.status == StatusLista.finalizada)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: successGreen.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Finalizada',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$comprados de $total itens',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    'R\$ ${formatarMoeda(totalGasto)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (total > 0)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: progress,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    strokeWidth: 4,
                  ),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
