import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/componente_repository.dart';
import '../../data/insumo_repository.dart';
import '../../data/produto_repository.dart';
import '../model/componente_com_custo.dart';
import '../model/insumo.dart';
import '../model/item_componente.dart';
import '../model/item_componente_com_insumo.dart';
import '../model/item_ficha_com_insumo.dart';
import '../model/item_ficha_tecnica.dart';
import '../model/porcao.dart';
import '../model/porcao_com_custo.dart';
import '../model/produto_com_custo.dart';
import '../model/produto_componente.dart';
import '../model/produto_componente_completo.dart';
import '../model/tamanho_componente_com_custo.dart';

/// Custeia uma porção a partir dos itens soltos e dos componentes aplicados.
/// Extraído para ser usado tanto na listagem quanto em cálculos pontuais.
PorcaoComCusto _custearPorcao({
  required Porcao porcao,
  required List<ItemFichaTecnica> itens,
  required List<ProdutoComponente> vinculos,
  required Map<int, Insumo> insumosById,
  required Map<int, List<ItemComponente>> itensPorTamanho,
}) {
  final custoItens = itens.fold<double>(0.0, (sum, item) {
    final insumo = insumosById[item.insumoId];
    if (insumo == null) return sum;
    return sum + ItemFichaComInsumo(item: item, insumo: insumo).custo;
  });

  final custoComponentes = vinculos.fold<double>(0.0, (sum, vinculo) {
    final itensDoTamanho = itensPorTamanho[vinculo.tamanhoComponenteId] ?? const [];
    final custoComponente = itensDoTamanho.fold<double>(0.0, (s, item) {
      final insumo = insumosById[item.insumoId];
      if (insumo == null) return s;
      return s + ItemComponenteComInsumo(item: item, insumo: insumo).custo;
    });
    return sum + custoComponente * vinculo.multiplicador;
  });

  final quantidadeItens =
      itens.length +
      vinculos.fold<int>(
        0,
        (sum, vinculo) =>
            sum + (itensPorTamanho[vinculo.tamanhoComponenteId]?.length ?? 0),
      );

  return PorcaoComCusto(
    porcao: porcao,
    custoTotal: custoItens + custoComponentes,
    quantidadeItens: quantidadeItens,
  );
}

/// Lista todos os produtos com suas porções custeadas. Cada porção soma seus
/// itens soltos + os componentes aplicados (cada um com seu multiplicador).
/// Reativo: reemite quando produtos, porções, insumos (preços), itens de
/// ficha, componentes ou vínculos mudam.
Stream<List<ProdutoComCusto>> getProdutosComCusto({
  required ProdutoRepository produtoRepository,
  required InsumoRepository insumoRepository,
  required ComponenteRepository componenteRepository,
}) {
  return Rx.combineLatest6(
    produtoRepository.getAllProdutos(),
    produtoRepository.getAllPorcoes(),
    insumoRepository.getAllInsumos(),
    produtoRepository.getAllItensFicha(),
    produtoRepository.getAllProdutoComponentes(),
    componenteRepository.getAllItensComponente(),
    (produtos, porcoes, insumos, itens, vinculos, itensComponente) {
      final insumosById = {for (final i in insumos) i.id: i};
      final porcoesByProduto = porcoes.groupListsBy((p) => p.produtoId);
      final itensByPorcao = itens.groupListsBy((i) => i.porcaoId);
      final vinculosByPorcao = vinculos.groupListsBy((v) => v.porcaoId);
      final itensPorTamanho = itensComponente.groupListsBy(
        (i) => i.tamanhoComponenteId,
      );

      return produtos.map((produto) {
        final porcoesDoProduto = [...?porcoesByProduto[produto.id]]
          ..sort((a, b) => a.ordem.compareTo(b.ordem));

        return ProdutoComCusto(
          produto: produto,
          porcoes: porcoesDoProduto
              .map(
                (porcao) => _custearPorcao(
                  porcao: porcao,
                  itens: itensByPorcao[porcao.id] ?? const [],
                  vinculos: vinculosByPorcao[porcao.id] ?? const [],
                  insumosById: insumosById,
                  itensPorTamanho: itensPorTamanho,
                ),
              )
              .toList(),
        );
      }).toList();
    },
  );
}

/// Ficha técnica de uma porção: itens com o insumo correspondente e o custo
/// de cada item (considerando perda/rendimento). Reativo a mudanças de preço
/// dos insumos.
Stream<List<ItemFichaComInsumo>> getFichaTecnica({
  required ProdutoRepository produtoRepository,
  required InsumoRepository insumoRepository,
  required int porcaoId,
}) {
  return Rx.combineLatest2(
    produtoRepository.getItensFichaByPorcao(porcaoId),
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

/// Itens de um tamanho de componente, com o insumo correspondente e o custo
/// de cada item. Reativo a mudanças de preço dos insumos. Equivalente a
/// [getFichaTecnica], mas para dentro de um componente.
Stream<List<ItemComponenteComInsumo>> getItensTamanho({
  required ComponenteRepository componenteRepository,
  required InsumoRepository insumoRepository,
  required int tamanhoComponenteId,
}) {
  return Rx.combineLatest2(
    componenteRepository.getItensByTamanho(tamanhoComponenteId),
    insumoRepository.getAllInsumos(),
    (itens, insumos) {
      final insumosById = {for (final i in insumos) i.id: i};
      return itens
          .map((item) {
            final insumo = insumosById[item.insumoId];
            return insumo == null
                ? null
                : ItemComponenteComInsumo(item: item, insumo: insumo);
          })
          .nonNulls
          .toList();
    },
  );
}

/// Componentes aplicados a uma porção, enriquecidos com os dados do
/// componente, do tamanho aplicado e seus itens (com insumo), e o custo da
/// parcela na porção (× multiplicador). Reativo a mudanças de vínculos,
/// componentes, tamanhos, itens e preços de insumos.
Stream<List<ProdutoComponenteCompleto>> getProdutoComponentes({
  required ProdutoRepository produtoRepository,
  required ComponenteRepository componenteRepository,
  required InsumoRepository insumoRepository,
  required int porcaoId,
}) {
  return Rx.combineLatest6(
    produtoRepository.getProdutoComponentesByPorcao(porcaoId),
    componenteRepository.getAllComponentes(),
    componenteRepository.getAllTamanhosComponente(),
    componenteRepository.getAllItensComponente(),
    insumoRepository.getAllInsumos(),
    componenteRepository.getAllTipos(),
    (vinculos, componentes, tamanhos, itens, insumos, tipos) {
      final componentesById = {for (final c in componentes) c.id: c};
      final tamanhosById = {for (final t in tamanhos) t.id: t};
      final itensByTamanho = itens.groupListsBy((i) => i.tamanhoComponenteId);
      final insumosById = {for (final i in insumos) i.id: i};
      final tiposById = {for (final t in tipos) t.id: t};

      return vinculos
          .map((vinculo) {
            final componente = componentesById[vinculo.componenteId];
            if (componente == null) return null;
            final itensEnriquecidos =
                (itensByTamanho[vinculo.tamanhoComponenteId] ?? const [])
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
              tamanhoNome: tamanhosById[vinculo.tamanhoComponenteId]?.nome,
            );
          })
          .nonNulls
          .toList();
    },
  );
}

/// Lista todos os componentes com seus tamanhos custeados (cada tamanho com
/// seus próprios itens). Reativo a mudanças de componentes, tamanhos, itens
/// e preços de insumos.
Stream<List<ComponenteComCusto>> getComponentes({
  required ComponenteRepository componenteRepository,
  required InsumoRepository insumoRepository,
}) {
  return Rx.combineLatest5(
    componenteRepository.getAllComponentes(),
    componenteRepository.getAllTamanhosComponente(),
    componenteRepository.getAllItensComponente(),
    insumoRepository.getAllInsumos(),
    componenteRepository.getAllTipos(),
    (componentes, tamanhos, itens, insumos, tipos) {
      final tamanhosByComponente = tamanhos.groupListsBy((t) => t.componenteId);
      final itensByTamanho = itens.groupListsBy((i) => i.tamanhoComponenteId);
      final insumosById = {for (final i in insumos) i.id: i};
      final tiposById = {for (final t in tipos) t.id: t};

      return componentes.map((componente) {
        final tamanhosDoComponente = [...?tamanhosByComponente[componente.id]]
          ..sort((a, b) => a.ordem.compareTo(b.ordem));

        final tamanhosComCusto = tamanhosDoComponente.map((tamanho) {
          final itensDoTamanho = itensByTamanho[tamanho.id] ?? const [];
          final custoTotal = itensDoTamanho.fold<double>(0.0, (sum, item) {
            final insumo = insumosById[item.insumoId];
            if (insumo == null) return sum;
            return sum +
                ItemComponenteComInsumo(item: item, insumo: insumo).custo;
          });
          return TamanhoComponenteComCusto(
            tamanho: tamanho,
            custoTotal: custoTotal,
            quantidadeItens: itensDoTamanho.length,
          );
        }).toList();

        return ComponenteComCusto(
          componente: componente,
          tamanhos: tamanhosComCusto,
          tipoNome: tiposById[componente.tipoComponenteId]?.nome,
        );
      }).toList();
    },
  );
}
