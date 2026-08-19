import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/componente_com_custo.dart';
import '../../domain/model/item_ficha_com_insumo.dart';
import '../../domain/model/item_ficha_tecnica.dart';
import '../../domain/model/porcao.dart';
import '../../domain/model/produto.dart';
import '../../domain/model/produto_componente.dart';
import '../../domain/model/produto_componente_completo.dart';
import '../../domain/usecase/componente_usecases.dart' as componente_usecase;
import '../../domain/usecase/cost_engine.dart';
import '../../domain/usecase/produto_usecases.dart' as produto_usecase;
import '../../providers/repository_providers.dart';

/// Porções de um produto, na ordem de exibição.
final porcoesProvider = StreamProvider.family<List<Porcao>, int>((
  ref,
  produtoId,
) {
  return ref.watch(produtoRepositoryProvider).getPorcoesByProduto(produtoId);
});

/// Ficha técnica (insumos soltos) de uma **porção**.
final fichaTecnicaProvider =
    StreamProvider.family<List<ItemFichaComInsumo>, int>((ref, porcaoId) {
      return getFichaTecnica(
        produtoRepository: ref.watch(produtoRepositoryProvider),
        insumoRepository: ref.watch(insumoRepositoryProvider),
        porcaoId: porcaoId,
      );
    });

/// Componentes aplicados a uma **porção**.
final produtoComponentesProvider =
    StreamProvider.family<List<ProdutoComponenteCompleto>, int>((
      ref,
      porcaoId,
    ) {
      return getProdutoComponentes(
        produtoRepository: ref.watch(produtoRepositoryProvider),
        componenteRepository: ref.watch(componenteRepositoryProvider),
        insumoRepository: ref.watch(insumoRepositoryProvider),
        porcaoId: porcaoId,
      );
    });

final componentesLibraryProvider = StreamProvider<List<ComponenteComCusto>>((
  ref,
) {
  return getComponentes(
    componenteRepository: ref.watch(componenteRepositoryProvider),
    insumoRepository: ref.watch(insumoRepositoryProvider),
  );
});

class ProdutoDetailActions {
  ProdutoDetailActions(this.ref, this.produtoId);
  final Ref ref;
  final int produtoId;

  // ── Produto ──────────────────────────────────────────────────────────────

  Future<void> updateProduto(String nome, String? emoji) {
    return produto_usecase.saveProduto(
      ref.read(produtoRepositoryProvider),
      Produto(id: produtoId, nome: nome, emoji: emoji),
    );
  }

  Future<void> deleteProduto(Produto produto) {
    return ref.read(produtoRepositoryProvider).deleteProduto(produto);
  }

  // ── Porções ──────────────────────────────────────────────────────────────

  /// Cria uma porção nova, opcionalmente copiando a ficha de outra porção.
  Future<int> addPorcao({
    required String nome,
    required int ordem,
    required double margemAlvoPercentual,
    double? precoVendaAtual,
    int? copiarFichaDaPorcaoId,
  }) {
    return produto_usecase.criarPorcao(
      ref.read(produtoRepositoryProvider),
      produtoId: produtoId,
      nome: nome,
      ordem: ordem,
      margemAlvoPercentual: margemAlvoPercentual,
      precoVendaAtual: precoVendaAtual,
      copiarFichaDaPorcaoId: copiarFichaDaPorcaoId,
    );
  }

  Future<void> updatePorcao(
    Porcao porcao, {
    required String nome,
    required double margemAlvoPercentual,
    required double? precoVendaAtual,
  }) {
    return produto_usecase.savePorcao(
      ref.read(produtoRepositoryProvider),
      porcao.copyWith(
        nome: nome,
        margemAlvoPercentual: margemAlvoPercentual,
        precoVendaAtual: precoVendaAtual,
        clearPrecoVendaAtual: precoVendaAtual == null,
      ),
    );
  }

  Future<void> deletePorcao(Porcao porcao) {
    return ref.read(produtoRepositoryProvider).deletePorcao(porcao);
  }

  /// Copia a ficha de outra porção para [porcaoDestinoId], substituindo o
  /// conteúdo atual dela.
  Future<void> copiarFichaDePorcao(int porcaoOrigemId, int porcaoDestinoId) {
    return produto_usecase.duplicateFichaTecnica(
      ref.read(produtoRepositoryProvider),
      porcaoOrigemId,
      porcaoDestinoId,
    );
  }

  // ── Ficha técnica da porção ─────────────────────────────────────────────

  Future<void> addItemFicha(
    int porcaoId,
    int insumoId,
    double quantidade,
    double perda,
  ) {
    return produto_usecase.saveItemFicha(
      ref.read(produtoRepositoryProvider),
      ItemFichaTecnica(
        porcaoId: porcaoId,
        insumoId: insumoId,
        quantidade: quantidade,
        perdaPercentual: perda,
      ),
    );
  }

  Future<void> updateItemFicha(
    ItemFichaTecnica item,
    double quantidade,
    double perda,
  ) {
    return produto_usecase.saveItemFicha(
      ref.read(produtoRepositoryProvider),
      item.copyWith(quantidade: quantidade, perdaPercentual: perda),
    );
  }

  Future<void> removeItemFicha(ItemFichaTecnica item) {
    return ref.read(produtoRepositoryProvider).deleteItemFicha(item);
  }

  Future<void> addComponente(
    int porcaoId,
    int componenteId,
    int tamanhoComponenteId,
    double multiplicador,
  ) {
    return componente_usecase.addComponenteToPorcao(
      ref.read(produtoRepositoryProvider),
      porcaoId: porcaoId,
      componenteId: componenteId,
      tamanhoComponenteId: tamanhoComponenteId,
      multiplicador: multiplicador,
    );
  }

  Future<void> updateMultiplicador(
    ProdutoComponente vinculo,
    double multiplicador,
  ) {
    return componente_usecase.updateProdutoComponenteMultiplicador(
      ref.read(produtoRepositoryProvider),
      vinculo,
      multiplicador,
    );
  }

  Future<void> removeComponente(ProdutoComponente vinculo) {
    return ref.read(produtoRepositoryProvider).deleteProdutoComponente(vinculo);
  }
}

final produtoDetailActionsProvider = Provider.family<ProdutoDetailActions, int>(
  (ref, produtoId) {
    return ProdutoDetailActions(ref, produtoId);
  },
);
