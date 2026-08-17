import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/model/tipo_componente.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/multiplicador_utils.dart';
import 'componente_form_dialog.dart';
import 'componentes_controller.dart';

class ComponentesScreen extends ConsumerWidget {
  const ComponentesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentesAsync = ref.watch(componentesLibraryProvider);
    final uiState = ref.watch(componentesControllerProvider);
    final controller = ref.read(componentesControllerProvider.notifier);

    ref.listen(componentesControllerProvider.select((s) => s.showFormDialog), (prev, next) {
      if (next) {
        showDialog<void>(
          context: context,
          builder: (_) => ComponenteFormDialog(
            componente: ref.read(componentesControllerProvider).componenteEmEdicao,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Componentes')),
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
                    selected: uiState.filtroTipo == null,
                    onSelected: (_) => controller.onFiltroChange(null),
                  ),
                  const SizedBox(width: 8),
                  for (final tipo in TipoComponente.values) ...[
                    FilterChip(
                      label: Text(formatarTipo(tipo)),
                      selected: uiState.filtroTipo == tipo,
                      onSelected: (_) => controller.onFiltroChange(tipo),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: componentesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: purplePrimary)),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (componentes) {
                final filtrados = uiState.filtroTipo == null
                    ? componentes
                    : componentes.where((c) => c.componente.tipo == uiState.filtroTipo).toList();
                if (filtrados.isEmpty) {
                  return const EmptyState(
                    icon: Icons.widgets,
                    title: 'Nenhum componente cadastrado',
                    subtitle:
                        'Componentes são blocos reutilizáveis (massa, sabor, embalagem) que você aplica em vários produtos',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = filtrados[i];
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
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: purpleContainer,
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                          child: Text(
                                            formatarTipo(item.componente.tipo),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(color: purpleOnContainer),
                                          ),
                                        ),
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
                                  Text('custo inteiro',
                                      style: Theme.of(context).textTheme.labelSmall),
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
