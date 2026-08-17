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

    // Uma query só para todas as tendências. Antes era uma por insumo, em
    // laço sequencial, re-executado a cada emissão dos três streams — o que
    // travava a UI visivelmente na abertura do app.
    var tendencias = <int, TendenciaPreco>{};
    try {
      tendencias = await getTendenciasPorInsumo(historicoRepo);
    } catch (_) {
      // sem histórico legível: segue com todos estáveis
    }

    final insumosComTendencia = [
      for (final insumo in insumos)
        InsumoComTendencia(
          insumo: insumo,
          tendencia: tendencias[insumo.id] ?? TendenciaPreco.estavel,
          ultimoPreco: insumo.custoAtual,
        ),
    ];
    return HomeData(
      ultimaLista: listas.isEmpty ? null : listas.first,
      todasListas: listas,
      insumosComTendencia: insumosComTendencia,
      produtosComCusto: produtos,
    );
  });
});
