import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/categoria_insumo.dart';
import '../../domain/model/insumo.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import 'insumo_form_dialog.dart';
import 'insumos_controller.dart';

class InsumosScreen extends ConsumerWidget {
  const InsumosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumosAsync = ref.watch(insumosStreamProvider);
    final uiState = ref.watch(insumosControllerProvider);
    final controller = ref.read(insumosControllerProvider.notifier);

    ref.listen(insumosControllerProvider.select((s) => s.error), (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
        controller.clearError();
      }
    });

    ref.listen(insumosControllerProvider.select((s) => s.showFormDialog), (prev, next) {
      if (next) {
        showDialog<void>(
          context: context,
          builder: (_) => InsumoFormDialog(
            insumo: ref.read(insumosControllerProvider).insumoEmEdicao,
            onConfirm: ({
              required nome,
              required categoria,
              required unidadeCompra,
              required unidadeUso,
              required fatorConversao,
              required custoAtual,
            }) =>
                controller.save(
              nome: nome,
              categoria: categoria,
              unidadeCompra: unidadeCompra,
              unidadeUso: unidadeUso,
              fatorConversao: fatorConversao,
              custoAtual: custoAtual,
            ),
          ),
        ).then((_) => controller.onHideForm());
      }
    });

    ref.listen(insumosControllerProvider.select((s) => s.insumoParaExcluir), (prev, next) {
      if (next != null) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir insumo?'),
            content: Text('"${next.nome}" e seu histórico de preços serão excluídos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.delete();
                },
                child: const Text('Excluir', style: TextStyle(color: errorRed)),
              ),
            ],
          ),
        ).then((_) => controller.onHideDeleteConfirm());
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Insumos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.onShowForm(),
        backgroundColor: yellowSecondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Insumo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: uiState.filtroCategoria == null,
                  onSelected: (_) => controller.onFiltroChange(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Insumos'),
                  selected: uiState.filtroCategoria == CategoriaInsumo.insumo,
                  onSelected: (_) => controller.onFiltroChange(CategoriaInsumo.insumo),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Embalagens'),
                  selected: uiState.filtroCategoria == CategoriaInsumo.embalagem,
                  onSelected: (_) =>
                      controller.onFiltroChange(CategoriaInsumo.embalagem),
                ),
              ],
            ),
          ),
          Expanded(
            child: insumosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: purplePrimary)),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (insumos) {
                final filtrados = uiState.filtroCategoria == null
                    ? insumos
                    : insumos.where((i) => i.categoria == uiState.filtroCategoria).toList();
                if (filtrados.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum insumo cadastrado',
                    subtitle:
                        'Cadastre insumos e embalagens com o custo por unidade para montar as fichas técnicas',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final insumo = filtrados[i];
                    return _InsumoRow(
                      insumo: insumo,
                      onTap: () => controller.onShowForm(insumo),
                      onDelete: () => controller.onShowDeleteConfirm(insumo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: null,
    );
  }
}

class _InsumoRow extends StatelessWidget {
  const _InsumoRow({required this.insumo, required this.onTap, required this.onDelete});
  final Insumo insumo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static String _formatarFator(double valor) {
    return valor % 1.0 == 0.0 ? valor.toInt().toString() : valor.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            insumo.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (insumo.categoria == CategoriaInsumo.embalagem) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: yellowContainer,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              'embalagem',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: yellowOnContainer),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '1 ${insumo.unidadeCompra} = ${_formatarFator(insumo.fatorConversao)} ${insumo.unidadeUso}',
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
                  Text(
                    'R\$ ${formatarMoeda(insumo.custoAtual)}/${insumo.unidadeCompra}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'R\$ ${formatarMoeda(insumo.custoPorUnidadeUso)}/${insumo.unidadeUso}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Excluir insumo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
