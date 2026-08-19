import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/insumo.dart';
import '../../theme/app_theme.dart';
import '../components/editar_quantidade_dialog.dart';
import '../components/emoji_picker_field.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/insumo_quantidade_row.dart';
import '../insumos/insumos_controller.dart' show insumosStreamProvider;
import 'componente_detail_controller.dart';
import 'componente_form_dialog.dart';
import 'componentes_controller.dart';

class ComponenteDetailScreen extends ConsumerWidget {
  const ComponenteDetailScreen({super.key, required this.componenteId});
  final int componenteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentesAsync = ref.watch(componentesLibraryProvider);
    final actions = ref.read(componenteDetailActionsProvider(componenteId));

    final item = componentesAsync.maybeWhen(
      data: (list) => list.where((c) => c.componente.id == componenteId).firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.componente.nome ?? 'Componente', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: item == null
                ? null
                : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => ComponenteFormDialog(
                        componente: item.componente,
                        tipoNomeAtual: item.tipoNome,
                        onConfirm: actions.updateComponente,
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: errorRed),
            onPressed: item == null
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir componente?'),
                        content: const Text(
                          'O componente será removido dos produtos que o utilizam. Esta ação não pode ser desfeita.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await actions.deleteComponente();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            child: const Text('Excluir', style: TextStyle(color: errorRed)),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      body: item == null
          ? const Center(child: CircularProgressIndicator(color: purplePrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        EmojiAvatar(
                          emoji: item.componente.emoji,
                          fallback: Icons.widgets,
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.componente.nome,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                '${item.quantidadeItens} insumo(s) por inteiro',
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: purplePrimary,
                                  ),
                            ),
                            Text('custo inteiro', style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Insumos',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () => _showAddItemDialog(context, ref, actions),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Insumo'),
                    ),
                  ],
                ),
                if (item.itens.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_outlined,
                    title: 'Componente sem insumos',
                    subtitle:
                        'Adicione os insumos deste bloco. Ele será aplicado inteiro (ou fracionado) nos produtos',
                  )
                else
                  ...item.itens.map(
                    (i) => InsumoQuantidadeRow(
                      nome: i.insumo.nome,
                      quantidade: i.item.quantidade,
                      unidade: i.insumo.unidadeUso,
                      perdaPercentual: i.item.perdaPercentual,
                      custo: i.custo,
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => EditarQuantidadeDialog(
                          titulo: i.insumo.nome,
                          unidadeUso: i.insumo.unidadeUso,
                          quantidadeInicial: i.item.quantidade,
                          perdaInicial: i.item.perdaPercentual,
                          onConfirm: (quantidade, perda) =>
                              actions.updateItem(i.item, quantidade, perda),
                        ),
                      ),
                      onDelete: () => actions.removeItem(i.item),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, ComponenteDetailActions actions) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddInsumoToComponenteSheet(onAdd: actions.addItem),
    );
  }
}

/// Folha de adicionar um insumo já cadastrado a um componente. O botão
/// "Adicionar" fica sempre no cabeçalho fixo (nunca atrás do teclado) — só o
/// conteúdo abaixo rola, seguindo o mesmo padrão do produto_item_sheet do
/// CofreNuvem.
class _AddInsumoToComponenteSheet extends ConsumerStatefulWidget {
  const _AddInsumoToComponenteSheet({required this.onAdd});
  final Future<void> Function(int insumoId, double quantidade, double perda) onAdd;

  @override
  ConsumerState<_AddInsumoToComponenteSheet> createState() =>
      _AddInsumoToComponenteSheetState();
}

class _AddInsumoToComponenteSheetState extends ConsumerState<_AddInsumoToComponenteSheet> {
  Insumo? _selected;
  final _searchController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _perdaController = TextEditingController(text: '0');

  @override
  void dispose() {
    _searchController.dispose();
    _quantidadeController.dispose();
    _perdaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insumosAsync = ref.watch(insumosStreamProvider);
    final quantidadeVal = parseDecimalPtBr(_quantidadeController.text);
    final perdaVal = parseDecimalPtBr(_perdaController.text) ?? 0;
    final isValid = _selected != null && quantidadeVal != null && quantidadeVal > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                Text('Adicionar insumo',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
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
            ),
            const SizedBox(height: 8),
            if (_selected == null) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(labelText: 'Buscar insumo'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
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
    );
  }
}
