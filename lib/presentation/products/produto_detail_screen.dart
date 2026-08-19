import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/model/componente_com_custo.dart';
import '../../domain/model/insumo.dart';
import '../../domain/model/item_ficha_com_insumo.dart';
import '../../domain/model/porcao.dart';
import '../../domain/model/porcao_com_custo.dart';
import '../../domain/model/produto.dart';
import '../../domain/model/produto_componente_completo.dart';
import '../../theme/app_theme.dart';
import '../components/back_or_home_button.dart';
import '../components/confirm_dialog.dart';
import '../components/editar_quantidade_dialog.dart';
import '../components/emoji_picker_field.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/multiplicador_utils.dart';
import '../components/responsive.dart';
import '../components/tutorial/tutorial_button.dart';
import '../components/tutorial/tutorial_keys.dart';
import '../components/tutorial/tutorial_passos.dart';
import '../insumos/insumos_controller.dart' show insumosStreamProvider;
import 'porcao_form_dialog.dart';
import 'produto_detail_controller.dart';
import 'produto_form_dialog.dart';
import 'produtos_screen.dart' show produtosComCustoProvider;

/// Tela da ficha técnica de um produto.
///
/// Um produto tem uma ou mais **porções** (tamanhos). Com uma porção só —
/// o caso comum — a barra de porções fica escondida e a tela se comporta
/// como antes, referindo-se ao produto inteiro.
class ProdutoDetailScreen extends ConsumerStatefulWidget {
  const ProdutoDetailScreen({super.key, required this.produtoId});
  final int produtoId;

  @override
  ConsumerState<ProdutoDetailScreen> createState() =>
      _ProdutoDetailScreenState();
}

class _ProdutoDetailScreenState extends ConsumerState<ProdutoDetailScreen> {
  /// Null = ainda não escolhida; cai na primeira porção disponível.
  int? _porcaoSelecionadaId;

  int get _produtoId => widget.produtoId;

  @override
  Widget build(BuildContext context) {
    final produtosAsync = ref.watch(produtosComCustoProvider);
    final porcoesAsync = ref.watch(porcoesProvider(_produtoId));
    final actions = ref.read(produtoDetailActionsProvider(_produtoId));

    final item = produtosAsync.maybeWhen(
      data: (list) => list.where((p) => p.produto.id == _produtoId).firstOrNull,
      orElse: () => null,
    );
    final porcoes = porcoesAsync.maybeWhen(
      data: (lista) => lista,
      orElse: () => const <Porcao>[],
    );

    final porcaoAtual =
        porcoes.where((p) => p.id == _porcaoSelecionadaId).firstOrNull ??
        porcoes.firstOrNull;
    final custoDaPorcao = porcaoAtual == null
        ? null
        : item?.porcoes.where((p) => p.porcao.id == porcaoAtual.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Row(
          children: [
            if (item?.produto.emoji != null) ...[
              Text(item!.produto.emoji!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                item?.produto.nome ?? 'Produto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar produto',
            onPressed: item == null
                ? null
                : () => showResponsiveFormSheet<void>(
                    context,
                    builder: (_) => ProdutoFormDialog(
                      produto: item.produto,
                      onConfirm: (nome, emoji, _, _) =>
                          actions.updateProduto(nome, emoji),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: errorRed),
            tooltip: 'Excluir produto',
            onPressed: item == null
                ? null
                : () =>
                      _confirmDeleteProduto(context, actions, item.produto, () {
                        context.pop();
                      }),
          ),
          const TutorialButton(tela: TutorialTela.produtoDetalhe),
        ],
      ),
      body: item == null || porcaoAtual == null || custoDaPorcao == null
          ? const Center(child: CircularProgressIndicator(color: purplePrimary))
          : MaxWidthCenter(
              child: _CorpoPorcao(
                produtoId: _produtoId,
                porcoes: porcoes,
                porcaoAtual: porcaoAtual,
                custoDaPorcao: custoDaPorcao,
                actions: actions,
                onSelecionarPorcao: (id) =>
                    setState(() => _porcaoSelecionadaId = id),
                onAdicionarPorcao: () =>
                    _showPorcaoFormDialog(context, actions, porcoes),
                onEditarPorcao: () => _showPorcaoFormDialog(
                  context,
                  actions,
                  porcoes,
                  porcaoParaEditar: porcaoAtual,
                ),
                onExcluirPorcao: () =>
                    _confirmDeletePorcao(context, actions, porcaoAtual),
              ),
            ),
    );
  }

  /// Abre o formulário de porção. Sem [porcaoParaEditar] é criação — e aí
  /// oferece copiar a ficha de uma porção existente.
  void _showPorcaoFormDialog(
    BuildContext context,
    ProdutoDetailActions actions,
    List<Porcao> porcoes, {
    Porcao? porcaoParaEditar,
  }) {
    final isCriacao = porcaoParaEditar == null;
    final margemPadrao = porcoes.isEmpty
        ? 30.0
        : porcoes.last.margemAlvoPercentual;

    showResponsiveFormSheet<void>(
      context,
      builder: (_) => PorcaoFormDialog(
        porcao: porcaoParaEditar,
        porcoesParaCopiar: isCriacao ? porcoes : const [],
        margemPadrao: margemPadrao,
        onConfirm:
            ({
              required nome,
              required margemAlvo,
              precoVenda,
              copiarFichaDaPorcaoId,
            }) async {
              if (isCriacao) {
                final novoId = await actions.addPorcao(
                  nome: nome,
                  ordem: porcoes.length,
                  margemAlvoPercentual: margemAlvo,
                  precoVendaAtual: precoVenda,
                  copiarFichaDaPorcaoId: copiarFichaDaPorcaoId,
                );
                if (mounted) setState(() => _porcaoSelecionadaId = novoId);
              } else {
                await actions.updatePorcao(
                  porcaoParaEditar,
                  nome: nome,
                  margemAlvoPercentual: margemAlvo,
                  precoVendaAtual: precoVenda,
                );
              }
            },
      ),
    );
  }

  void _confirmDeletePorcao(
    BuildContext context,
    ProdutoDetailActions actions,
    Porcao porcao,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir porção "${porcao.nome}"?'),
        content: const Text(
          'A ficha técnica desta porção também será excluída. '
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
              await actions.deletePorcao(porcao);
              if (mounted) setState(() => _porcaoSelecionadaId = null);
            },
            child: const Text('Excluir', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduto(
    BuildContext context,
    ProdutoDetailActions actions,
    Produto produto,
    VoidCallback onDeleted,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: const Text(
          'Todas as porções e suas fichas técnicas também serão excluídas. '
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
              await actions.deleteProduto(produto);
              onDeleted();
            },
            child: const Text('Excluir', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }
}

/// Conteúdo da porção selecionada: barra de porções, resumo de custo e a
/// ficha técnica (componentes aplicados + insumos avulsos).
class _CorpoPorcao extends ConsumerWidget {
  const _CorpoPorcao({
    required this.produtoId,
    required this.porcoes,
    required this.porcaoAtual,
    required this.custoDaPorcao,
    required this.actions,
    required this.onSelecionarPorcao,
    required this.onAdicionarPorcao,
    required this.onEditarPorcao,
    required this.onExcluirPorcao,
  });

  final int produtoId;
  final List<Porcao> porcoes;
  final Porcao porcaoAtual;
  final PorcaoComCusto custoDaPorcao;
  final ProdutoDetailActions actions;
  final ValueChanged<int> onSelecionarPorcao;
  final VoidCallback onAdicionarPorcao;
  final VoidCallback onEditarPorcao;
  final VoidCallback onExcluirPorcao;

  bool get _temMultiplasPorcoes => porcoes.length > 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fichaAsync = ref.watch(fichaTecnicaProvider(porcaoAtual.id));
    final componentesAsync = ref.watch(
      produtoComponentesProvider(porcaoAtual.id),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _PorcoesBar(
          key: TutorialKeys.produtoPorcoes,
          porcoes: porcoes,
          porcaoAtualId: porcaoAtual.id,
          onSelecionar: onSelecionarPorcao,
          onAdicionar: onAdicionarPorcao,
        ),
        const SizedBox(height: 12),
        _ResumoCustoCard(
          key: TutorialKeys.produtoResumoCusto,
          item: custoDaPorcao,
          mostrarNomeDaPorcao: _temMultiplasPorcoes,
          onEditar: onEditarPorcao,
          onExcluir: _temMultiplasPorcoes ? onExcluirPorcao : null,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Ficha Técnica',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // Botões compactos: com 3 (Copiar/Componente/Insumo) essa linha
            // já estourava a largura em telas estreitas de celular.
            Row(
              key: TutorialKeys.produtoAcoesFicha,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_temMultiplasPorcoes)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showCopiarDePorcaoDialog(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar'),
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showAddComponenteDialog(context),
                  icon: const Icon(Icons.widgets, size: 16),
                  label: const Text('Componente'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showAddInsumoDialog(context),
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
                    Text(
                      'Componentes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...componentes.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ComponenteNoProdutoCard(
                          item: c,
                          onTap: () => _showEditMultiplicadorDialog(context, c),
                          onDelete: () async {
                            final confirmou = await confirmarAcao(
                              context,
                              titulo: 'Remover componente?',
                              mensagem:
                                  '"${c.componente.nome}" será removido '
                                  'desta porção.',
                              rotuloConfirmar: 'Remover',
                            );
                            if (confirmou) actions.removeComponente(c.vinculo);
                          },
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
                      'Adicione componentes reutilizáveis ou insumos avulsos para calcular o custo desta porção',
                ),
              );
            }
            if (itens.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Insumos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                ...itens.map(
                  (i) => _InsumoQuantidadeRow(
                    item: i,
                    onTap: () => _showEditItemDialog(context, i),
                    onDelete: () async {
                      final confirmou = await confirmarAcao(
                        context,
                        titulo: 'Excluir insumo?',
                        mensagem:
                            '"${i.insumo.nome}" será removido desta porção.',
                        rotuloConfirmar: 'Excluir',
                      );
                      if (confirmou) actions.removeItemFicha(i.item);
                    },
                  ),
                ),
              ],
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

  void _showEditItemDialog(BuildContext context, ItemFichaComInsumo item) {
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

  void _showAddInsumoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddInsumoDialog(
        onAdd: (insumoId, quantidade, perda) =>
            actions.addItemFicha(porcaoAtual.id, insumoId, quantidade, perda),
      ),
    );
  }

  void _showAddComponenteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddComponenteDialog(
        onAdd: (componenteId, tamanhoComponenteId, multiplicador) =>
            actions.addComponente(
              porcaoAtual.id,
              componenteId,
              tamanhoComponenteId,
              multiplicador,
            ),
      ),
    );
  }

  /// Copia a ficha de outra porção do mesmo produto, substituindo a atual.
  /// É o caminho de "a G tem os mesmos insumos da P, só muda a quantidade".
  void _showCopiarDePorcaoDialog(BuildContext context) {
    final outras = porcoes.where((p) => p.id != porcaoAtual.id).toList();
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
              Text(
                'Substitui a ficha de "${porcaoAtual.nome}" (componentes e '
                'insumos) pela ficha de:',
              ),
              const SizedBox(height: 8),
              ...outras.map(
                (outra) => TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final confirmou = await confirmarAcao(
                      context,
                      titulo: 'Copiar ficha técnica?',
                      mensagem:
                          'A ficha atual de "${porcaoAtual.nome}" (componentes '
                          'e insumos) será substituída pela de "${outra.nome}". '
                          'Esta ação não pode ser desfeita.',
                      rotuloConfirmar: 'Copiar',
                    );
                    if (confirmou) {
                      actions.copiarFichaDePorcao(outra.id, porcaoAtual.id);
                    }
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      outra.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

/// Seletor de porções. Com uma porção só, vira um convite discreto a criar
/// tamanhos — quem vende produto de tamanho único não vê complexidade.
class _PorcoesBar extends StatelessWidget {
  const _PorcoesBar({
    super.key,
    required this.porcoes,
    required this.porcaoAtualId,
    required this.onSelecionar,
    required this.onAdicionar,
  });

  final List<Porcao> porcoes;
  final int porcaoAtualId;
  final ValueChanged<int> onSelecionar;
  final VoidCallback onAdicionar;

  @override
  Widget build(BuildContext context) {
    if (porcoes.length <= 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onAdicionar,
          icon: const Icon(Icons.straighten, size: 16),
          label: const Text('Adicionar tamanho (P/M/G)'),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final porcao in porcoes) ...[
            ChoiceChip(
              label: Text(porcao.nome),
              selected: porcao.id == porcaoAtualId,
              onSelected: (_) => onSelecionar(porcao.id),
            ),
            const SizedBox(width: 8),
          ],
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Tamanho'),
            onPressed: onAdicionar,
          ),
        ],
      ),
    );
  }
}

class _ResumoCustoCard extends StatelessWidget {
  const _ResumoCustoCard({
    super.key,
    required this.item,
    required this.mostrarNomeDaPorcao,
    required this.onEditar,
    this.onExcluir,
  });

  final PorcaoComCusto item;
  final bool mostrarNomeDaPorcao;
  final VoidCallback onEditar;

  /// Null quando só existe uma porção (não faz sentido excluir a última).
  final VoidCallback? onExcluir;

  @override
  Widget build(BuildContext context) {
    final margemReal = item.margemRealPercentual;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (mostrarNomeDaPorcao)
                  Expanded(
                    child: Text(
                      item.porcao.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Editar margem e preço',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditar,
                ),
                if (onExcluir != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: errorRed),
                    tooltip: 'Excluir porção',
                    visualDensity: VisualDensity.compact,
                    onPressed: onExcluir,
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custo por porção',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'R\$ ${formatarMoeda(item.custoTotal)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Preço sugerido',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'R\$ ${formatarMoeda(item.precoSugerido)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: purplePrimary,
                          ),
                    ),
                    Text(
                      'margem ${item.porcao.margemAlvoPercentual.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
            if (item.porcao.precoVendaAtual != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preço praticado: R\$ ${formatarMoeda(item.porcao.precoVendaAtual!)}',
                  ),
                  if (margemReal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.margemAbaixoDaMeta
                            ? warningContainer
                            : successContainer,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Margem ${margemReal.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: item.margemAbaixoDaMeta
                              ? warningOrange
                              : successGreen,
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
  const _ComponenteNoProdutoCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final ProdutoComponenteCompleto item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // O InkWell cobre só o conteúdo (ícone/nome/tipo), nunca o botão de
  // lixeira -- um IconButton dentro da área de um InkWell maior podia não
  // registrar o toque (nenhum DELETE chegava a sair pra rede, confirmado
  // nos logs do Supabase). Separar as duas regiões elimina a ambiguidade.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    EmojiAvatar(
                      emoji: item.componente.emoji,
                      fallback: Icons.widgets,
                      radius: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.componente.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Row(
                            children: [
                              if (item.tipoNome != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
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
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  '${item.quantidadeItens} insumo(s) · ${descreverMultiplicador(item.vinculo.multiplicador)}'
                                  '${item.tamanhoNome == null || item.tamanhoNome == 'Único' ? '' : ' · ${item.tamanhoNome}'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${formatarMoeda(item.custo)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'custo na porção',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _InsumoQuantidadeRow extends StatelessWidget {
  const _InsumoQuantidadeRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final ItemFichaComInsumo item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // O InkWell cobre só o título/subtítulo, nunca o botão de lixeira -- ver
  // nota equivalente em InsumoQuantidadeRow (components/insumo_quantidade_row.dart).
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.insumo.nome,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.item.quantidade % 1.0 == 0.0 ? item.item.quantidade.toInt() : item.item.quantidade} ${item.insumo.unidadeUso}'
                      '${item.item.perdaPercentual > 0 ? ' · perda ${item.item.perdaPercentual.toStringAsFixed(0)}%' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text('R\$ ${formatarMoeda(item.custo)}'),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DivisorDialog extends StatefulWidget {
  const _DivisorDialog({
    required this.titulo,
    required this.divisorInicial,
    required this.onConfirm,
  });
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
          Text(
            'Divisão do componente',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, value) in [
                ('Inteiro', '1'),
                ('1/2', '2'),
                ('1/3', '3'),
                ('1/4', '4'),
              ])
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
            decoration: const InputDecoration(
              labelText: 'Dividir por (nº de partes/sabores)',
            ),
            inputFormatters: [decimalPtBrInputFormatter],
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
  final Future<void> Function(int insumoId, double quantidade, double perda)
  onAdd;

  @override
  ConsumerState<_AddInsumoDialog> createState() => _AddInsumoDialogState();
}

class _AddInsumoDialogState extends ConsumerState<_AddInsumoDialog> {
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
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

class _AddComponenteDialog extends ConsumerStatefulWidget {
  const _AddComponenteDialog({required this.onAdd});
  final Future<void> Function(
    int componenteId,
    int tamanhoComponenteId,
    double multiplicador,
  )
  onAdd;

  @override
  ConsumerState<_AddComponenteDialog> createState() =>
      _AddComponenteDialogState();
}

class _AddComponenteDialogState extends ConsumerState<_AddComponenteDialog> {
  /// Componente escolhido que tem mais de um tamanho -- pede qual tamanho
  /// antes de confirmar. Fica null e o toque já confirma quando o
  /// componente só tem o tamanho "Único" (o caso comum).
  ComponenteComCusto? _escolhendoTamanhoDe;

  @override
  Widget build(BuildContext context) {
    final componentesAsync = ref.watch(componentesLibraryProvider);
    final escolhendoTamanhoDe = _escolhendoTamanhoDe;

    if (escolhendoTamanhoDe != null) {
      return AlertDialog(
        title: Text(escolhendoTamanhoDe.componente.nome),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              children: escolhendoTamanhoDe.tamanhos
                  .map(
                    (t) => ListTile(
                      title: Text(t.tamanho.nome),
                      subtitle: Text('R\$ ${formatarMoeda(t.custoTotal)}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onAdd(
                          escolhendoTamanhoDe.componente.id,
                          t.tamanho.id,
                          1.0,
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _escolhendoTamanhoDe = null),
            child: const Text('Voltar'),
          ),
        ],
      );
    }

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
                          if (c.temMultiplosTamanhos) {
                            setState(() => _escolhendoTamanhoDe = c);
                            return;
                          }
                          Navigator.of(context).pop();
                          final tamanhoId = c.tamanhoPrincipal?.tamanho.id;
                          if (tamanhoId != null) {
                            widget.onAdd(c.componente.id, tamanhoId, 1.0);
                          }
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
