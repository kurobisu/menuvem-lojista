import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecase/tendencia_usecase.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/tendencia_indicador.dart';
import '../home/home_controller.dart';

final priceHistoryProvider = StreamProvider<List<InsumoComTendencia>>((ref) {
  final insumoRepo = ref.watch(insumoRepositoryProvider);
  final historicoRepo = ref.watch(historicoPrecoRepositoryProvider);
  return insumoRepo.getAllInsumos().asyncMap((insumos) async {
    final result = <InsumoComTendencia>[];
    for (final insumo in insumos) {
      try {
        final tendencia = await getTendenciaPreco(historicoRepo, insumo.id);
        result.add(InsumoComTendencia(
          insumo: insumo,
          tendencia: tendencia,
          ultimoPreco: insumo.custoAtual,
        ));
      } catch (_) {}
    }
    return result;
  });
});

class PriceHistoryScreen extends ConsumerWidget {
  const PriceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(priceHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Preços')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purplePrimary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (itens) {
          if (itens.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'Sem histórico ainda',
              subtitle:
                  'Finalize listas de compras com itens vinculados a insumos para ver variações de preço aqui',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: itens.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    '${itens.length} insumos monitorados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              final item = itens[i - 1];
              return Card(
                child: InkWell(
                  onTap: () => context.push('/price-history/${item.insumo.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.insumo.nome,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'por ${item.insumo.unidadeCompra}',
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
                              'R\$ ${formatarMoeda(item.ultimoPreco)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            TendenciaIndicador(tendencia: item.tendencia, showLabel: true),
                          ],
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
    );
  }
}
