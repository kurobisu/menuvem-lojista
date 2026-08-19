import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/componente_repository.dart';
import '../../data/insumo_repository.dart';
import '../../data/produto_repository.dart';
import '../model/componente_com_custo.dart';
import '../model/item_componente_com_insumo.dart';
import '../model/item_ficha_com_insumo.dart';
import '../model/produto_com_custo.dart';
import '../model/produto_componente_completo.dart';

/// Lista todos os produtos com o custo calculado a partir da ficha técnica
/// (itens soltos + componentes aplicados, cada um com seu multiplicador).
/// Reativo: reemite quando produtos, insumos (preços), itens de ficha,
/// componentes ou vínculos mudam, recalculando custos e margens.
Stream<List<ProdutoComCusto>> getProdutosComCusto({
  required ProdutoRepository produtoRepository,
  required InsumoRepository insumoRepository,
  required ComponenteRepository componenteRepository,
}) {
  return Rx.combineLatest5(
    produtoRepository.getAllProdutos(),
    insumoRepository.getAllInsumos(),
    produtoRepository.getAllItensFicha(),
    produtoRepository.getAllProdutoComponentes(),
    componenteRepository.getAllItensComponente(),
    (produtos, insumos, itens, vinculos, itensComponente) {
      final insumosById = {for (final i in insumos) i.id: i};
      final itensByProduto = itens.groupListsBy((i) => i.produtoId);
      final vinculosByProduto = vinculos.groupListsBy((v) => v.produtoId);
      final itensCompByComponente = itensComponente.groupListsBy(
        (i) => i.componenteId,
      );

      return produtos.map((produto) {
        final itensProduto = itensByProduto[produto.id] ?? const [];
        final custoItens = itensProduto.fold<double>(0.0, (sum, item) {
          final insumo = insumosById[item.insumoId];
          if (insumo == null) return sum;
          return sum + ItemFichaComInsumo(item: item, insumo: insumo).custo;
        });

        final vinculosProduto = vinculosByProduto[produto.id] ?? const [];
        final custoComponentes = vinculosProduto.fold<double>(0.0, (sum, vinculo) {
          final itensDoComponente =
              itensCompByComponente[vinculo.componenteId] ?? const [];
          final custoComponente = itensDoComponente.fold<double>(0.0, (s, item) {
            final insumo = insumosById[item.insumoId];
            if (insumo == null) return s;
            return s +
                ItemComponenteComInsumo(item: item, insumo: insumo).custo;
          });
          return sum + custoComponente * vinculo.multiplicador;
        });

        final quantidadeItens = itensProduto.length +
            vinculosProduto.fold<int>(
              0,
              (sum, vinculo) =>
                  sum +
                  (itensCompByComponente[vinculo.componenteId]?.length ?? 0),
            );

        return ProdutoComCusto(
          produto: produto,
          custoTotal: custoItens + custoComponentes,
          quantidadeItens: quantidadeItens,
        );
      }).toList();
    },
  );
}

/// Ficha técnica de um produto: itens com o insumo correspondente e o custo
/// de cada item (considerando perda/rendimento). Reativo a mudanças de preço
/// dos insumos.
Stream<List<ItemFichaComInsumo>> getFichaTecnica({
  required ProdutoRepository produtoRepository,
  required InsumoRepository insumoRepository,
  required int produtoId,
}) {
  return Rx.combineLatest2(
    produtoRepository.getItensFichaByProduto(produtoId),
    insumoRepository.getAllInsumos(),
    (itens, insumos) {
      final insumosById = {for (final i in insumos) i.id: i};
      return itens
          .map((item) {
            final insumo = insumosById[item.insumoId];
            return insumo == null
                ? null
                : ItemFichaComInsumo(item: item, insumo: insumo);
          })
          .nonNulls
          .toList();
    },
  );
}

/// Componentes aplicados a um produto, enriquecidos com os dados do
/// componente e seus itens (com insumo) e o custo da parcela no produto (×
/// multiplicador). Reativo a mudanças de vínculos, componentes, itens e
/// preços de insumos.
Stream<List<ProdutoComponenteCompleto>> getProdutoComponentes({
  required ProdutoRepository produtoRepository,
  required ComponenteRepository componenteRepository,
  required InsumoRepository insumoRepository,
  required int produtoId,
}) {
  return Rx.combineLatest5(
    produtoRepository.getProdutoComponentesByProduto(produtoId),
    componenteRepository.getAllComponentes(),
    componenteRepository.getAllItensComponente(),
    insumoRepository.getAllInsumos(),
    componenteRepository.getAllTipos(),
    (vinculos, componentes, itens, insumos, tipos) {
      final componentesById = {for (final c in componentes) c.id: c};
      final itensByComponente = itens.groupListsBy((i) => i.componenteId);
      final insumosById = {for (final i in insumos) i.id: i};
      final tiposById = {for (final t in tipos) t.id: t};

      return vinculos
          .map((vinculo) {
            final componente = componentesById[vinculo.componenteId];
            if (componente == null) return null;
            final itensEnriquecidos = (itensByComponente[vinculo.componenteId] ??
                    const [])
                .map((item) {
                  final insumo = insumosById[item.insumoId];
                  return insumo == null
                      ? null
                      : ItemComponenteComInsumo(item: item, insumo: insumo);
                })
                .nonNulls
                .toList();
            return ProdutoComponenteCompleto(
              vinculo: vinculo,
              componente: componente,
              itens: itensEnriquecidos,
              tipoNome: tiposById[componente.tipoComponenteId]?.nome,
            );
          })
          .nonNulls
          .toList();
    },
  );
}

/// Lista todos os componentes com seus itens (enriquecidos com insumo) e o
/// custo por inteiro (multiplicador 1). Reativo a mudanças de componentes,
/// itens e preços de insumos.
Stream<List<ComponenteComCusto>> getComponentes({
  required ComponenteRepository componenteRepository,
  required InsumoRepository insumoRepository,
}) {
  return Rx.combineLatest4(
    componenteRepository.getAllComponentes(),
    componenteRepository.getAllItensComponente(),
    insumoRepository.getAllInsumos(),
    componenteRepository.getAllTipos(),
    (componentes, itens, insumos, tipos) {
      final itensByComponente = itens.groupListsBy((i) => i.componenteId);
      final insumosById = {for (final i in insumos) i.id: i};
      final tiposById = {for (final t in tipos) t.id: t};

      return componentes.map((componente) {
        final itensEnriquecidos =
            (itensByComponente[componente.id] ?? const [])
                .map((item) {
                  final insumo = insumosById[item.insumoId];
                  return insumo == null
                      ? null
                      : ItemComponenteComInsumo(item: item, insumo: insumo);
                })
                .nonNulls
                .toList();
        return ComponenteComCusto(
          componente: componente,
          itens: itensEnriquecidos,
          tipoNome: tiposById[componente.tipoComponenteId]?.nome,
        );
      }).toList();
    },
  );
}
