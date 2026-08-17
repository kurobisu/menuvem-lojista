import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/model/produto.dart';
import '../../domain/model/produto_com_custo.dart';
import '../../domain/usecase/cost_engine.dart';
import '../../domain/usecase/produto_usecases.dart' as usecase;
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import 'produto_form_dialog.dart';

final produtosComCustoProvider = StreamProvider<List<ProdutoComCusto>>((ref) {
  return getProdutosComCusto(
    produtoRepository: ref.watch(produtoRepositoryProvider),
    insumoRepository: ref.watch(insumoRepositoryProvider),
    componenteRepository: ref.watch(componenteRepositoryProvider),
  );
});

class ProdutosScreen extends ConsumerWidget {
  const ProdutosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(produtosComCustoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => ProdutoFormDialog(
            onConfirm: (nome, margem, preco) async {
              final id = await usecase.saveProduto(
                ref.read(produtoRepositoryProvider),
                Produto(nome: nome, margemAlvoPercentual: margem, precoVendaAtual: preco),
              );
              if (context.mounted) context.push('/produtos/$id');
            },
          ),
        ),
        backgroundColor: yellowSecondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purplePrimary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (produtos) {
          if (produtos.isEmpty) {
            return const EmptyState(
              icon: Icons.restaurant_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle: 'Cadastre um produto e monte a ficha técnica para calcular o custo e o preço ideal',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: produtos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ProdutoCard(
              item: produtos[i],
              onTap: () => context.push('/produtos/${produtos[i].produto.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _ProdutoCard extends StatelessWidget {
  const _ProdutoCard({required this.item, required this.onTap});
  final ProdutoComCusto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final margemReal = item.margemRealPercentual;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.produto.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          item.quantidadeItens == 0
                              ? 'Ficha técnica vazia'
                              : '${item.quantidadeItens} insumo(s) na ficha',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (item.margemAbaixoDaMeta)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.warning, color: warningOrange, size: 20),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Custo R\$ ${formatarMoeda(item.custoTotal)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        'R\$ ${formatarMoeda(item.precoSugerido)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: purplePrimary,
                            ),
                      ),
                      Text(
                        'preço sugerido',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _MargemChip(
                    label: 'Meta ${item.produto.margemAlvoPercentual.toStringAsFixed(1)}%',
                    container: purpleContainer,
                    content: purpleOnContainer,
                  ),
                  if (margemReal != null)
                    _MargemChip(
                      label: 'Atual ${margemReal.toStringAsFixed(1)}%',
                      container: item.margemAbaixoDaMeta ? warningContainer : successContainer,
                      content: item.margemAbaixoDaMeta ? warningOrange : successGreen,
                    )
                  else
                    _MargemChip(
                      label: 'Sem preço de venda',
                      container: Theme.of(context).colorScheme.surfaceContainerHighest,
                      content: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MargemChip extends StatelessWidget {
  const _MargemChip({required this.label, required this.container, required this.content});
  final String label;
  final Color container;
  final Color content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: container, borderRadius: BorderRadius.circular(50)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: content)),
    );
  }
}
