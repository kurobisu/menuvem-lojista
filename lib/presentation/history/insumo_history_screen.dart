import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/model/tendencia_preco.dart';
import '../../domain/usecase/tendencia_usecase.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import '../components/back_or_home_button.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/responsive.dart';
import '../components/tendencia_indicador.dart';

final insumoHistoryProvider = StreamProvider.family((ref, int insumoId) {
  final insumoRepo = ref.watch(insumoRepositoryProvider);
  final historicoRepo = ref.watch(historicoPrecoRepositoryProvider);

  return Rx.combineLatest2(
    insumoRepo.getAllInsumos().map(
      (list) => list.where((i) => i.id == insumoId).firstOrNull,
    ),
    historicoRepo.getHistoricoByInsumo(insumoId),
    (insumo, historico) => (insumo, historico),
  ).asyncMap((tuple) async {
    final (insumo, historico) = tuple;
    TendenciaPreco tendencia = TendenciaPreco.estavel;
    try {
      tendencia = await getTendenciaPreco(historicoRepo, insumoId);
    } catch (_) {}
    return (insumo: insumo, historico: historico, tendencia: tendencia);
  });
});

class InsumoHistoryScreen extends ConsumerWidget {
  const InsumoHistoryScreen({super.key, required this.insumoId});
  final int insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insumoHistoryProvider(insumoId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: async.maybeWhen(
          data: (d) => Text(d.insumo?.nome ?? 'Histórico'),
          orElse: () => const Text('Histórico'),
        ),
        actions: [
          async.maybeWhen(
            data: (d) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TendenciaIndicador(
                tendencia: d.tendencia,
                showLabel: true,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: MaxWidthCenter(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: purplePrimary),
          ),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (d) {
            final insumo = d.insumo;
            final historico = d.historico;
            final formatter = DateFormat("dd/MM/yyyy 'às' HH:mm");
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (insumo != null)
                  Card(
                    margin: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custo atual',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                'R\$ ${formatarMoeda(insumo.custoAtual)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'por ${insumo.unidadeCompra}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${historico.length} compras',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                'R\$ ${formatarMoeda(insumo.custoPorUnidadeUso)}/${insumo.unidadeUso}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: yellowSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Histórico de compras',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (historico.isEmpty)
                  const EmptyState(
                    icon: Icons.insights_outlined,
                    title: 'Sem registros',
                    subtitle:
                        'Este insumo não tem histórico de preços. Finalize uma lista de compras com ele para começar a registrar.',
                  )
                else
                  ...historico.reversed.map(
                    (h) => Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.receipt,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          title: Text(
                            'R\$ ${formatarMoeda(h.preco)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatter.format(h.data)),
                              if (h.listaComprasNome.isNotEmpty)
                                Text(
                                  h.listaComprasNome,
                                  style: const TextStyle(color: purplePrimary),
                                ),
                            ],
                          ),
                        ),
                        const Divider(indent: 16, endIndent: 16),
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
}
