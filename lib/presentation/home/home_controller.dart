import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/model/insumo.dart';
import '../../domain/model/lista_compras.dart';
import '../../domain/model/produto_com_custo.dart';
import '../../domain/model/tendencia_preco.dart';
import '../../domain/usecase/cost_engine.dart';
import '../../domain/usecase/tendencia_usecase.dart';
import '../../providers/repository_providers.dart';

class InsumoComTendencia {
  final Insumo insumo;
  final TendenciaPreco tendencia;
  final double ultimoPreco;

  const InsumoComTendencia({
    required this.insumo,
    required this.tendencia,
    required this.ultimoPreco,
  });
}

class HomeData {
  final ListaCompras? ultimaLista;
  final List<ListaCompras> todasListas;
  final List<InsumoComTendencia> insumosComTendencia;
  final List<ProdutoComCusto> produtosComCusto;

  const HomeData({
    required this.ultimaLista,
    required this.todasListas,
    required this.insumosComTendencia,
    required this.produtosComCusto,
  });

  /// Produtos com preço praticado cuja margem real caiu abaixo da margem-alvo.
  List<ProdutoComCusto> get produtosAbaixoDaMeta =>
      produtosComCusto.where((p) => p.margemAbaixoDaMeta).toList();
}

final homeDataProvider = StreamProvider<HomeData>((ref) {
  final listaRepo = ref.watch(listaComprasRepositoryProvider);
  final insumoRepo = ref.watch(insumoRepositoryProvider);
  final produtoRepo = ref.watch(produtoRepositoryProvider);
  final componenteRepo = ref.watch(componenteRepositoryProvider);
  final historicoRepo = ref.watch(historicoPrecoRepositoryProvider);

  final produtosComCustoStream = getProdutosComCusto(
    produtoRepository: produtoRepo,
    insumoRepository: insumoRepo,
    componenteRepository: componenteRepo,
  );

  return Rx.combineLatest3(
    listaRepo.getAllListas(),
    insumoRepo.getAllInsumos(),
    produtosComCustoStream,
    (listas, insumos, produtos) => (listas, insumos, produtos),
  ).asyncMap((tuple) async {
    final (listas, insumos, produtos) = tuple;
    final insumosComTendencia = <InsumoComTendencia>[];
    for (final insumo in insumos) {
      try {
        final tendencia = await getTendenciaPreco(historicoRepo, insumo.id);
        insumosComTendencia.add(
          InsumoComTendencia(
            insumo: insumo,
            tendencia: tendencia,
            ultimoPreco: insumo.custoAtual,
          ),
        );
      } catch (_) {
        // ignora insumo sem histórico legível, como no original
      }
    }
    return HomeData(
      ultimaLista: listas.isEmpty ? null : listas.first,
      todasListas: listas,
      insumosComTendencia: insumosComTendencia,
      produtosComCusto: produtos,
    );
  });
});
