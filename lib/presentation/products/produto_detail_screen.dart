import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/model/insumo.dart';
import '../../domain/model/item_ficha_com_insumo.dart';
import '../../domain/model/produto_componente_completo.dart';
import '../../theme/app_theme.dart';
import '../components/editar_quantidade_dialog.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/multiplicador_utils.dart';
import '../insumos/insumos_controller.dart' show insumosStreamProvider;
import 'produto_detail_controller.dart';
import 'produto_form_dialog.dart';
import 'produtos_screen.dart' show produtosComCustoProvider;

class ProdutoDetailScreen extends ConsumerWidget {
  const ProdutoDetailScreen({super.key, required this.produtoId});
  final int produtoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produtosAsync = ref.watch(produtosComCustoProvider);
    final fichaAsync = ref.watch(fichaTecnicaProvider(produtoId));
    final componentesAsync = ref.watch(produtoComponentesProvider(produtoId));
    final actions = ref.read(produtoDetailActionsProvider(produtoId));

    final item = produtosAsync.maybeWhen(
      data: (list) => list.where((p) => p.produto.id == produtoId).firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.produto.nome ?? 'Produto', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar produto',
            onPressed: item == null
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (_) => ProdutoFormDialog(
                        produto: item.produto,
                        onConfirm: actions.updateProduto,
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: errorRed),
            tooltip: 'Excluir produto',
            onPressed: item == null
                ? null
                : () => _confirmDeleteProduto(context, actions, item.produto, () {
                      context.pop();
                    }),
          ),
        ],
      ),
      body: item == null
          ? const Center(child: CircularProgressIndicator(color: purplePrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _ResumoCustoCard(item: item),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ficha Técnica',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showDuplicateDialog(context, ref, actions),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copiar'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddComponenteDialog(context, ref, actions),
                          icon: const Icon(Icons.widgets, size: 16),
                          label: const Text('Componente'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddInsumoDialog(context, ref, actions),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Insumo'),
                        ),
                      ],
                    ),
                  ],
                ),
                componentesAsync.maybeWhen(
                  data: (componentes) => componentes.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Componentes',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    )),
                            const SizedBox(height: 4),
                            ...componentes.map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _ComponenteNoProdutoCard(
                                  item: c,
                                  onTap: () => _showEditMultiplicadorDialog(context, actions, c),
                                  onDelete: () => actions.removeComponente(c.vinculo),
                                ),
                              ),
                            ),
                          ],
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                fichaAsync.maybeWhen(
                  data: (itens) {
                    final componentesVazio = componentesAsync.maybeWhen(
                      data: (c) => c.isEmpty,
                      orElse: () => true,
                    );
                    if (itens.isEmpty && componentesVazio) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: EmptyState(
                          icon: Icons.receipt_outlined,
                          title: 'Ficha técnica vazia',
                          subtitle:
                              'Adicione componentes reutilizáveis ou insumos avulsos para calcular o custo por porção',
                        ),
                      );
                    }
                    if (itens.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Insumos',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
                        const SizedBox(height: 4),
                        ...itens.map(
                          (i) => _InsumoQuantidadeRow(
                            item: i,
                            onTap: () => _showEditItemDialog(context, actions, i),
                            onDelete: () => actions.removeItemFicha(i.item),
                          ),
                        ),
                      ],
                    );
                  },
                  orElse: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: purplePrimary)),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmDeleteProduto(
    BuildContext context,
    ProdutoDetailActions actions,
    dynamic produto,
    VoidCallback onDeleted,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: const Text(
          'A ficha técnica também será excluída. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await actions.deleteProduto(produto);
              onDeleted();
            },
            child: const Text('Excluir', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    ProdutoDetailActions actions,
    ItemFichaComInsumo item,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => EditarQuantidadeDialog(
        titulo: item.insumo.nome,
        unidadeUso: item.insumo.unidadeUso,
        quantidadeInicial: item.item.quantidade,
        perdaInicial: item.item.perdaPercentual,
        onConfirm: (quantidade, perda) =>
            actions.updateItemFicha(item.item, quantidade, perda),
      ),
    );
  }

  void _showEditMultiplicadorDialog(
    BuildContext context,
    ProdutoDetailActions actions,
    ProdutoComponenteCompleto item,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _DivisorDialog(
        titulo: item.componente.nome,
        divisorInicial: divisorDeMultiplicador(item.vinculo.multiplicador),
        onConfirm: (multiplicador) =>
            actions.updateMultiplicador(item.vinculo, multiplicador),
      ),
    );
  }

  void _showAddInsumoDialog(BuildContext context, WidgetRef ref, ProdutoDetailActions actions) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddInsumoDialog(onAdd: actions.addItemFicha),
    );
  }

  void _showAddComponenteDialog(
    BuildContext context,
    WidgetRef ref,
    ProdutoDetailActions actions,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddComponenteDialog(onAdd: actions.addComponente),
    );
  }

  void _showDuplicateDialog(BuildContext context, WidgetRef ref, ProdutoDetailActions actions) {
    final outros = ref.read(produtosComCustoProvider).maybeWhen(
          data: (list) => list.where((p) => p.produto.id != produtoId).toList(),
          orElse: () => const [],
        );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copiar ficha técnica'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Substitui a ficha atual (componentes e insumos) pela ficha de:'),
              const SizedBox(height: 8),
              ...outros.map(
                (outro) => TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    actions.duplicateFrom(outro.produto.id);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(outro.produto.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _ResumoCustoCard extends StatelessWidget {
  const _ResumoCustoCard({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Custo por porção',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                    Text(
                      'R\$ ${formatarMoeda(item.custoTotal)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Preço sugerido',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                    Text(
                      'R\$ ${formatarMoeda(item.precoSugerido)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: purplePrimary,
                          ),
                    ),
                    Text('margem ${item.produto.margemAlvoPercentual.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            if (item.produto.precoVendaAtual != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preço praticado: R\$ ${formatarMoeda(item.produto.precoVendaAtual)}'),
                  if (item.margemRealPercentual != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.margemAbaixoDaMeta ? warningContainer : successContainer,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Margem ${item.margemRealPercentual.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: item.margemAbaixoDaMeta ? warningOrange : successGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComponenteNoProdutoCard extends StatelessWidget {
  const _ComponenteNoProdutoCard({required this.item, required this.onTap, required this.onDelete});
  final ProdutoComponenteCompleto item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.widgets, color: purplePrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.componente.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall),
                    Row(
                      children: [
                        if (item.tipoNome != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: purpleContainer,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(item.tipoNome!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: purpleOnContainer)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            '${item.quantidadeItens} insumo(s) · ${descreverMultiplicador(item.vinculo.multiplicador)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('R\$ ${formatarMoeda(item.custo)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text('custo no produto', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsumoQuantidadeRow extends StatelessWidget {
  const _InsumoQuantidadeRow({required this.item, required this.onTap, required this.onDelete});
  final ItemFichaComInsumo item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(item.insumo.nome),
        subtitle: Text(
          '${item.item.quantidade % 1.0 == 0.0 ? item.item.quantidade.toInt() : item.item.quantidade} ${item.insumo.unidadeUso}'
          '${item.item.perdaPercentual > 0 ? ' · perda ${item.item.perdaPercentual.toStringAsFixed(0)}%' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('R\$ ${formatarMoeda(item.custo)}'),
            IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _DivisorDialog extends StatefulWidget {
  const _DivisorDialog({required this.titulo, required this.divisorInicial, required this.onConfirm});
  final String titulo;
  final String divisorInicial;
  final void Function(double multiplicador) onConfirm;

  @override
  State<_DivisorDialog> createState() => _DivisorDialogState();
}

class _DivisorDialogState extends State<_DivisorDialog> {
  late final _controller = TextEditingController(text: widget.divisorInicial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divisorVal = parseDecimalPtBr(_controller.text);
    final isValid = divisorVal != null && divisorVal > 0;

    return AlertDialog(
      title: Text(widget.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Divisão do componente', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, value) in [('Inteiro', '1'), ('1/2', '2'), ('1/3', '3'), ('1/4', '4')])
                ChoiceChip(
                  label: Text(label),
                  selected: _controller.text.trim() == value,
                  onSelected: (_) => setState(() => _controller.text = value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Dividir por (nº de partes/sabores)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: isValid
              ? () {
                  widget.onConfirm(1.0 / divisorVal);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _AddInsumoDialog extends ConsumerStatefulWidget {
  const _AddInsumoDialog({required this.onAdd});
  final Future<void> Function(int insumoId, double quantidade, double perda) onAdd;

  @override
  ConsumerState<_AddInsumoDialog> createState() => _AddInsumoDialogState();
}

class _AddInsumoDialogState extends ConsumerState<_AddInsumoDialog> {
  Insumo? _selected;
  final _searchController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _perdaController = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    final insumosAsync = ref.watch(insumosStreamProvider);
    final quantidadeVal = parseDecimalPtBr(_quantidadeController.text);
    final perdaVal = parseDecimalPtBr(_perdaController.text) ?? 0;
    final isValid = _selected != null && quantidadeVal != null && quantidadeVal > 0;

    return AlertDialog(
      title: const Text('Adicionar insumo à ficha'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selected == null) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(labelText: 'Buscar insumo'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: insumosAsync.maybeWhen(
                  data: (insumos) {
                    final q = _searchController.text.trim().toLowerCase();
                    final filtrados = q.isEmpty
                        ? insumos
                        : insumos.where((i) => i.nome.toLowerCase().contains(q)).toList();
                    return ListView(
                      shrinkWrap: true,
                      children: filtrados
                          .map((i) => ListTile(
                                title: Text(i.nome),
                                subtitle: Text(i.unidadeUso),
                                onTap: () => setState(() => _selected = i),
                              ))
                          .toList(),
                    );
                  },
                  orElse: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ] else
              ListTile(
                tileColor: Theme.of(context).colorScheme.primaryContainer,
                title: Text(_selected!.nome),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selected = null),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantidadeController,
                    decoration: InputDecoration(
                      labelText: 'Quantidade (${_selected?.unidadeUso ?? ''})',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _perdaController,
                    decoration: const InputDecoration(labelText: 'Perda (%)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: isValid
              ? () {
                  widget.onAdd(_selected!.id, quantidadeVal, perdaVal);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class _AddComponenteDialog extends ConsumerWidget {
  const _AddComponenteDialog({required this.onAdd});
  final Future<void> Function(int componenteId, double multiplicador) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentesAsync = ref.watch(componentesLibraryProvider);
    return AlertDialog(
      title: const Text('Adicionar componente'),
      content: SizedBox(
        width: double.maxFinite,
        child: componentesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erro: $e'),
          data: (componentes) {
            if (componentes.isEmpty) {
              return const Text('Nenhum componente cadastrado ainda.');
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                children: componentes
                    .map(
                      (c) => ListTile(
                        title: Text(c.componente.nome),
                        subtitle: Text(
                          c.tipoNome == null
                              ? 'R\$ ${formatarMoeda(c.custo)}'
                              : '${c.tipoNome} · R\$ ${formatarMoeda(c.custo)}',
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onAdd(c.componente.id, 1.0);
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
      ],
    );
  }
}
