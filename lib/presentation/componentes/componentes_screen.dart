import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/model/componente_com_custo.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import 'componente_form_dialog.dart';
import 'componentes_controller.dart';

class ComponentesScreen extends ConsumerStatefulWidget {
  const ComponentesScreen({super.key});

  @override
  ConsumerState<ComponentesScreen> createState() => _ComponentesScreenState();
}

class _ComponentesScreenState extends ConsumerState<ComponentesScreen> {
  List<ComponenteComCusto>? _localOrder;
  bool _hasOrderChanges = false;
  bool _isSavingOrder = false;

  Future<void> _salvarOrdem(ComponentesController controller) async {
    final local = _localOrder;
    if (local == null || !_hasOrderChanges) return;
    setState(() => _isSavingOrder = true);
    await controller.salvarOrdemComponentes(local);
    if (!mounted) return;
    setState(() {
      _isSavingOrder = false;
      _hasOrderChanges = false;
      _localOrder = null;
    });
  }

  void _confirmDeleteTipo(BuildContext context, ComponentesController controller, int tipoId,
      String tipoNome) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir tipo?'),
        content: Text(
          '"$tipoNome" será excluído. Os componentes desse tipo ficarão sem tipo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteTipo(tipoId);
            },
            child: const Text('Excluir', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final componentesAsync = ref.watch(componentesLibraryProvider);
    final tiposAsync = ref.watch(tiposComponenteProvider);
    final uiState = ref.watch(componentesControllerProvider);
    final controller = ref.read(componentesControllerProvider.notifier);

    ref.listen(componentesControllerProvider.select((s) => s.showFormDialog), (prev, next) {
      if (next) {
        final state = ref.read(componentesControllerProvider);
        final componente = state.componenteEmEdicao;
        final tipos = ref.read(tiposComponenteProvider).asData?.value ?? const [];
        final tipoIdParaPrefill = componente?.tipoComponenteId ?? state.filtroTipoId;
        final tipoNome = tipos.where((t) => t.id == tipoIdParaPrefill).firstOrNull?.nome;
        showDialog<void>(
          context: context,
          builder: (_) => ComponenteFormDialog(
            componente: componente,
            tipoNomeAtual: tipoNome,
            onConfirm: controller.save,
          ),
        ).then((_) => controller.onHideForm());
      }
    });

    ref.listen(componentesControllerProvider.select((s) => s.componenteParaExcluir), (prev, next) {
      if (next != null) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir componente?'),
            content: Text(
              '"${next.componente.nome}" e seus itens serão excluídos. Ele também será removido dos produtos que o utilizam.',
            ),
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

    final podeReordenar = uiState.filtroTipoId == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Componentes'),
        actions: [
          if (_hasOrderChanges)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _isSavingOrder ? null : () => _salvarOrdem(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purplePrimary,
                  foregroundColor: Colors.white,
                ),
                icon: _isSavingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Salvar'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Reordenar tipos',
            onPressed: () => context.push('/componentes/tipos'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.onShowForm(),
        backgroundColor: yellowSecondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Componente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: uiState.filtroTipoId == null,
                    onSelected: (_) => controller.onFiltroChange(null),
                  ),
                  const SizedBox(width: 8),
                  for (final tipo in tiposAsync.asData?.value ?? const []) ...[
                    FilterChip(
                      label: Text(tipo.nome),
                      selected: uiState.filtroTipoId == tipo.id,
                      onSelected: (_) => controller.onFiltroChange(tipo.id),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _confirmDeleteTipo(context, controller, tipo.id, tipo.nome),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          if (!podeReordenar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Selecione "Todos" para reordenar os componentes',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Expanded(
            child: componentesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: purplePrimary)),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (componentes) {
                final filtrados = uiState.filtroTipoId == null
                    ? componentes
                    : componentes
                        .where((c) => c.componente.tipoComponenteId == uiState.filtroTipoId)
                        .toList();
                if (filtrados.isEmpty) {
                  return const EmptyState(
                    icon: Icons.widgets,
                    title: 'Nenhum componente cadastrado',
                    subtitle:
                        'Componentes são blocos reutilizáveis (massa, sabor, embalagem) que você aplica em vários produtos',
                  );
                }

                if (!podeReordenar) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ComponenteCard(item: filtrados[i]),
                  );
                }

                if (!_hasOrderChanges) _localOrder = List.of(filtrados);
                final lista = _localOrder!;

                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: lista.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final novaLista = List.of(lista);
                      final item = novaLista.removeAt(oldIndex);
                      novaLista.insert(newIndex, item);
                      _localOrder = novaLista;
                      _hasOrderChanges = true;
                    });
                  },
                  itemBuilder: (context, i) {
                    final item = lista[i];
                    return Padding(
                      key: ValueKey(item.componente.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ReorderableDelayedDragStartListener(
                        index: i,
                        child: _ComponenteCard(item: item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponenteCard extends ConsumerWidget {
  const _ComponenteCard({required this.item});
  final ComponenteComCusto item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(componentesControllerProvider.notifier);
    return Card(
      child: InkWell(
        onTap: () => context.push('/componentes/${item.componente.id}'),
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
                            item.componente.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (item.tipoNome != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: purpleContainer,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              item.tipoNome!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: purpleOnContainer),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      item.quantidadeItens == 0
                          ? 'Sem insumos'
                          : '${item.quantidadeItens} insumo(s) por inteiro',
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
                    'R\$ ${formatarMoeda(item.custo)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text('custo inteiro', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => controller.onShowDeleteConfirm(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
