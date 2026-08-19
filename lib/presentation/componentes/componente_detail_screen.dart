import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/model/insumo.dart';
import '../../domain/model/tamanho_componente.dart';
import '../../domain/model/tamanho_componente_com_custo.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import '../components/back_or_home_button.dart';
import '../components/confirm_dialog.dart';
import '../components/editar_quantidade_dialog.dart';
import '../components/emoji_picker_field.dart';
import '../components/empty_state.dart';
import '../components/form_sheet_header.dart';
import '../components/formatters.dart';
import '../components/insumo_quantidade_row.dart';
import '../components/responsive.dart';
import '../insumos/insumos_controller.dart' show insumosStreamProvider;
import 'componente_detail_controller.dart';
import 'componente_form_dialog.dart';
import 'componentes_controller.dart';
import 'tamanho_componente_form_dialog.dart';

class ComponenteDetailScreen extends ConsumerStatefulWidget {
  const ComponenteDetailScreen({super.key, required this.componenteId});
  final int componenteId;

  @override
  ConsumerState<ComponenteDetailScreen> createState() =>
      _ComponenteDetailScreenState();
}

class _ComponenteDetailScreenState
    extends ConsumerState<ComponenteDetailScreen> {
  /// Null = ainda não escolhido; cai no primeiro tamanho disponível.
  int? _tamanhoSelecionadoId;

  /// Duplicar copia todos os tamanhos e seus insumos, então pode levar um
  /// instante -- sem isso, o botão parecia não fazer nada e convidava a
  /// tocar de novo, criando cópias repetidas.
  bool _duplicando = false;

  int get _componenteId => widget.componenteId;

  @override
  Widget build(BuildContext context) {
    final componentesAsync = ref.watch(componentesLibraryProvider);
    final tamanhosAsync = ref.watch(tamanhosComponenteProvider(_componenteId));
    final actions = ref.read(componenteDetailActionsProvider(_componenteId));

    final item = componentesAsync.maybeWhen(
      data: (list) =>
          list.where((c) => c.componente.id == _componenteId).firstOrNull,
      orElse: () => null,
    );
    final tamanhos = tamanhosAsync.maybeWhen(
      data: (lista) => lista,
      orElse: () => const <TamanhoComponente>[],
    );

    final tamanhoAtual =
        tamanhos.where((t) => t.id == _tamanhoSelecionadoId).firstOrNull ??
        tamanhos.firstOrNull;
    final custoDoTamanho = tamanhoAtual == null
        ? null
        : item?.tamanhos
              .where((t) => t.tamanho.id == tamanhoAtual.id)
              .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Text(
          item?.componente.nome ?? 'Componente',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: item == null
                ? null
                : () => showResponsiveFormSheet<void>(
                    context,
                    builder: (_) => ComponenteFormDialog(
                      componente: item.componente,
                      tipoNomeAtual: item.tipoNome,
                      onConfirm: actions.updateComponente,
                    ),
                  ),
          ),
          IconButton(
            icon: _duplicando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.copy_outlined),
            tooltip: 'Duplicar',
            onPressed: item == null || _duplicando
                ? null
                : () async {
                    final confirmou = await confirmarAcao(
                      context,
                      titulo: 'Duplicar componente?',
                      mensagem:
                          'Cria uma cópia de "${item.componente.nome}" com '
                          'todos os tamanhos e insumos, pronta pra ajustar.',
                      rotuloConfirmar: 'Duplicar',
                      destrutivo: false,
                    );
                    if (!confirmou) return;
                    setState(() => _duplicando = true);
                    final novoId = await actions.duplicarComponente();
                    if (!context.mounted) return;
                    setState(() => _duplicando = false);
                    context.push('/componentes/$novoId');
                  },
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
                          child: const Text(
                            'Excluir',
                            style: TextStyle(color: errorRed),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      body: item == null || tamanhoAtual == null || custoDoTamanho == null
          ? const Center(child: CircularProgressIndicator(color: purplePrimary))
          : MaxWidthCenter(
              child: _CorpoTamanho(
                componenteId: _componenteId,
                emoji: item.componente.emoji,
                tamanhos: tamanhos,
                tamanhoAtual: tamanhoAtual,
                custoDoTamanho: custoDoTamanho,
                actions: actions,
                onSelecionarTamanho: (id) =>
                    setState(() => _tamanhoSelecionadoId = id),
                onAdicionarTamanho: () =>
                    _showTamanhoFormDialog(context, actions, tamanhos),
                onEditarTamanho: () => _showTamanhoFormDialog(
                  context,
                  actions,
                  tamanhos,
                  tamanhoParaEditar: tamanhoAtual,
                ),
                onExcluirTamanho: () =>
                    _confirmDeleteTamanho(context, actions, tamanhoAtual),
              ),
            ),
    );
  }

  /// Abre o formulário de tamanho. Sem [tamanhoParaEditar] é criação — e aí
  /// oferece copiar os itens de um tamanho existente.
  void _showTamanhoFormDialog(
    BuildContext context,
    ComponenteDetailActions actions,
    List<TamanhoComponente> tamanhos, {
    TamanhoComponente? tamanhoParaEditar,
  }) {
    final isCriacao = tamanhoParaEditar == null;

    showResponsiveFormSheet<void>(
      context,
      builder: (_) => TamanhoComponenteFormDialog(
        tamanho: tamanhoParaEditar,
        tamanhosParaCopiar: isCriacao ? tamanhos : const [],
        onConfirm: ({required nome, copiarItensDoTamanhoId}) async {
          if (isCriacao) {
            final novoId = await actions.addTamanho(
              nome: nome,
              copiarItensDoTamanhoId: copiarItensDoTamanhoId,
            );
            if (mounted) setState(() => _tamanhoSelecionadoId = novoId);
          } else {
            await actions.updateTamanho(tamanhoParaEditar, nome: nome);
          }
        },
      ),
    );
  }

  void _confirmDeleteTamanho(
    BuildContext context,
    ComponenteDetailActions actions,
    TamanhoComponente tamanho,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir tamanho "${tamanho.nome}"?'),
        content: const Text(
          'Os insumos deste tamanho também serão excluídos. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await actions.deleteTamanho(tamanho);
              if (mounted) setState(() => _tamanhoSelecionadoId = null);
            },
            child: const Text('Excluir', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }
}

/// Conteúdo do tamanho selecionado: barra de tamanhos, resumo e os insumos.
class _CorpoTamanho extends ConsumerWidget {
  const _CorpoTamanho({
    required this.componenteId,
    required this.emoji,
    required this.tamanhos,
    required this.tamanhoAtual,
    required this.custoDoTamanho,
    required this.actions,
    required this.onSelecionarTamanho,
    required this.onAdicionarTamanho,
    required this.onEditarTamanho,
    required this.onExcluirTamanho,
  });

  final int componenteId;
  final String? emoji;
  final List<TamanhoComponente> tamanhos;
  final TamanhoComponente tamanhoAtual;
  final TamanhoComponenteComCusto custoDoTamanho;
  final ComponenteDetailActions actions;
  final ValueChanged<int> onSelecionarTamanho;
  final VoidCallback onAdicionarTamanho;
  final VoidCallback onEditarTamanho;
  final VoidCallback onExcluirTamanho;

  bool get _temMultiplosTamanhos => tamanhos.length > 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itensAsync = ref.watch(itensTamanhoProvider(tamanhoAtual.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _TamanhosBar(
          tamanhos: tamanhos,
          tamanhoAtualId: tamanhoAtual.id,
          onSelecionar: onSelecionarTamanho,
          onAdicionar: onAdicionarTamanho,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                EmojiAvatar(emoji: emoji, fallback: Icons.widgets, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_temMultiplosTamanhos)
                        Text(
                          tamanhoAtual.nome,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      Text(
                        '${custoDoTamanho.quantidadeItens} insumo(s) por inteiro',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_temMultiplosTamanhos) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEditarTamanho,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onExcluirTamanho,
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${formatarMoeda(custoDoTamanho.custoTotal)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: purplePrimary,
                      ),
                    ),
                    Text(
                      'custo inteiro',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
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
            Text(
              'Insumos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () => _showAddItemDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Insumo'),
            ),
          ],
        ),
        itensAsync.maybeWhen(
          data: (itens) {
            if (itens.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_outlined,
                title: 'Componente sem insumos',
                subtitle:
                    'Adicione os insumos deste bloco. Ele será aplicado inteiro (ou fracionado) nos produtos',
              );
            }
            return Column(
              children: itens
                  .map(
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
                      onDelete: () async {
                        final confirmou = await confirmarAcao(
                          context,
                          titulo: 'Excluir insumo?',
                          mensagem:
                              '"${i.insumo.nome}" será removido deste tamanho.',
                          rotuloConfirmar: 'Excluir',
                        );
                        if (confirmou) actions.removeItem(i.item);
                      },
                    ),
                  )
                  .toList(),
            );
          },
          orElse: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: purplePrimary),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showResponsiveFormSheet<void>(
      context,
      builder: (_) => _AddInsumoToComponenteSheet(
        onAdd: (insumoId, quantidade, perda) =>
            actions.addItem(tamanhoAtual.id, insumoId, quantidade, perda),
      ),
    );
  }
}

/// Seletor de tamanhos. Com um tamanho só, vira um convite discreto a criar
/// tamanhos — quem cadastra o componente sem variação não vê complexidade.
/// Com mais de um, os chips viram arrastáveis (segurar e arrastar) pra
/// deixar na ordem que o usuário preferir — sem isso a ordem ficava por
/// ordem de criação, que não é necessariamente P/M/G.
class _TamanhosBar extends ConsumerStatefulWidget {
  const _TamanhosBar({
    required this.tamanhos,
    required this.tamanhoAtualId,
    required this.onSelecionar,
    required this.onAdicionar,
  });

  final List<TamanhoComponente> tamanhos;
  final int tamanhoAtualId;
  final ValueChanged<int> onSelecionar;
  final VoidCallback onAdicionar;

  @override
  ConsumerState<_TamanhosBar> createState() => _TamanhosBarState();
}

class _TamanhosBarState extends ConsumerState<_TamanhosBar> {
  List<TamanhoComponente>? _local;
  // ids na ordem recém-salva: o stream demora um instante pra reemitir
  // depois do UPDATE -- sem isso a barra "voltava" pra ordem antiga por um
  // instante. Mesma técnica de tipos_reorder_screen.dart.
  List<int>? _pendingSavedIds;

  Future<void> _reordenar(int oldIndex, int newIndex) async {
    final lista = _local ?? widget.tamanhos;
    final novaLista = List.of(lista);
    final item = novaLista.removeAt(oldIndex);
    novaLista.insert(newIndex, item);
    setState(() => _local = novaLista);

    final ordemPorId = {
      for (var i = 0; i < novaLista.length; i++) novaLista[i].id: i,
    };
    try {
      await ref
          .read(componenteRepositoryProvider)
          .updateOrdensTamanhos(ordemPorId);
      if (!mounted) return;
      // Se outro arrasto começou enquanto este salvava, `_local` já mudou de
      // novo -- não sobrescreve `_pendingSavedIds` com uma ordem que já não
      // é a atual, ou a barra podia "confirmar" a ordem errada.
      if (!identical(_local, novaLista)) return;
      setState(() => _pendingSavedIds = novaLista.map((t) => t.id).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _local = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a ordem: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tamanhos.length <= 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: widget.onAdicionar,
          icon: const Icon(Icons.straighten, size: 16),
          label: const Text('Adicionar tamanho'),
        ),
      );
    }

    if (_pendingSavedIds != null) {
      final currentIds = widget.tamanhos.map((t) => t.id).toList();
      final confirmado =
          const ListEquality<int>().equals(currentIds, _pendingSavedIds) ||
          currentIds.length != _pendingSavedIds!.length;
      if (confirmado) _pendingSavedIds = null;
    }
    if (_pendingSavedIds == null) {
      _local = List.of(widget.tamanhos);
    }
    final lista = _local!;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: lista.length,
              onReorderItem: (oldIndex, newIndex) =>
                  _reordenar(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final tamanho = lista[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(tamanho.id),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tamanho.nome),
                      selected: tamanho.id == widget.tamanhoAtualId,
                      onSelected: (_) => widget.onSelecionar(tamanho.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('Tamanho'),
          onPressed: widget.onAdicionar,
        ),
      ],
    );
  }
}

/// Folha de adicionar um insumo já cadastrado a um tamanho de componente. O
/// botão "Adicionar" fica sempre no cabeçalho fixo (nunca atrás do teclado)
/// — só o conteúdo abaixo rola, seguindo o mesmo padrão do produto_item_sheet
/// do CofreNuvem.
class _AddInsumoToComponenteSheet extends ConsumerStatefulWidget {
  const _AddInsumoToComponenteSheet({required this.onAdd});
  final Future<void> Function(int insumoId, double quantidade, double perda)
  onAdd;

  @override
  ConsumerState<_AddInsumoToComponenteSheet> createState() =>
      _AddInsumoToComponenteSheetState();
}

class _AddInsumoToComponenteSheetState
    extends ConsumerState<_AddInsumoToComponenteSheet> {
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
    final isValid =
        _selected != null && quantidadeVal != null && quantidadeVal > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSheetHeader(
              titulo: 'Adicionar insumo',
              rotuloSalvar: 'Adicionar',
              onCancelar: () => Navigator.of(context).pop(),
              onSalvar: isValid
                  ? () {
                      widget.onAdd(_selected!.id, quantidadeVal, perdaVal);
                      Navigator.of(context).pop();
                    }
                  : null,
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
                        : insumos
                              .where((i) => i.nome.toLowerCase().contains(q))
                              .toList();
                    return ListView(
                      shrinkWrap: true,
                      children: filtrados
                          .map(
                            (i) => ListTile(
                              title: Text(i.nome),
                              subtitle: Text(i.unidadeUso),
                              onTap: () => setState(() => _selected = i),
                            ),
                          )
                          .toList(),
                    );
                  },
                  orElse: () =>
                      const Center(child: CircularProgressIndicator()),
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
                    inputFormatters: [decimalPtBrInputFormatter],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _perdaController,
                    decoration: const InputDecoration(labelText: 'Perda (%)'),
                    inputFormatters: [decimalPtBrInputFormatter],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
