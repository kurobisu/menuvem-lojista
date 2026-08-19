import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/componente_com_custo.dart';
import '../../domain/model/item_ficha_com_insumo.dart';
import '../../domain/model/item_ficha_tecnica.dart';
import '../../domain/model/produto.dart';
import '../../domain/model/produto_componente.dart';
import '../../domain/model/produto_componente_completo.dart';
import '../../domain/usecase/componente_usecases.dart' as componente_usecase;
import '../../domain/usecase/cost_engine.dart';
import '../../domain/usecase/produto_usecases.dart' as produto_usecase;
import '../../providers/repository_providers.dart';

final fichaTecnicaProvider =
    StreamProvider.family<List<ItemFichaComInsumo>, int>((ref, produtoId) {
  return getFichaTecnica(
    produtoRepository: ref.watch(produtoRepositoryProvider),
    insumoRepository: ref.watch(insumoRepositoryProvider),
    produtoId: produtoId,
  );
});

final produtoComponentesProvider =
    StreamProvider.family<List<ProdutoComponenteCompleto>, int>((ref, produtoId) {
  return getProdutoComponentes(
    produtoRepository: ref.watch(produtoRepositoryProvider),
    componenteRepository: ref.watch(componenteRepositoryProvider),
    insumoRepository: ref.watch(insumoRepositoryProvider),
    produtoId: produtoId,
  );
});

final componentesLibraryProvider = StreamProvider<List<ComponenteComCusto>>((ref) {
  return getComponentes(
    componenteRepository: ref.watch(componenteRepositoryProvider),
    insumoRepository: ref.watch(insumoRepositoryProvider),
  );
});

class ProdutoDetailActions {
  ProdutoDetailActions(this.ref, this.produtoId);
  final Ref ref;
  final int produtoId;

  Future<void> updateProduto(
    String nome,
    double margemAlvo,
    double? precoVenda,
    String? emoji,
  ) {
    return produto_usecase.saveProduto(
      ref.read(produtoRepositoryProvider),
      Produto(
        id: produtoId,
        nome: nome,
        margemAlvoPercentual: margemAlvo,
        precoVendaAtual: precoVenda,
        emoji: emoji,
      ),
    );
  }

  Future<void> deleteProduto(Produto produto) {
    return ref.read(produtoRepositoryProvider).deleteProduto(produto);
  }

  Future<void> addItemFicha(int insumoId, double quantidade, double perda) {
    return produto_usecase.saveItemFicha(
      ref.read(produtoRepositoryProvider),
      ItemFichaTecnica(
        produtoId: produtoId,
        insumoId: insumoId,
        quantidade: quantidade,
        perdaPercentual: perda,
      ),
    );
  }

  Future<void> updateItemFicha(ItemFichaTecnica item, double quantidade, double perda) {
    return produto_usecase.saveItemFicha(
      ref.read(produtoRepositoryProvider),
      item.copyWith(quantidade: quantidade, perdaPercentual: perda),
    );
  }

  Future<void> removeItemFicha(ItemFichaTecnica item) {
    return ref.read(produtoRepositoryProvider).deleteItemFicha(item);
  }

  Future<void> addComponente(int componenteId, double multiplicador) {
    return componente_usecase.addComponenteToProduto(
      ref.read(produtoRepositoryProvider),
      produtoId: produtoId,
      componenteId: componenteId,
      multiplicador: multiplicador,
    );
  }

  Future<void> updateMultiplicador(ProdutoComponente vinculo, double multiplicador) {
    return componente_usecase.updateProdutoComponenteMultiplicador(
      ref.read(produtoRepositoryProvider),
      vinculo,
      multiplicador,
    );
  }

  Future<void> removeComponente(ProdutoComponente vinculo) {
    return ref.read(produtoRepositoryProvider).deleteProdutoComponente(vinculo);
  }

  Future<void> duplicateFrom(int produtoOrigemId) {
    return produto_usecase.duplicateFichaTecnica(
      ref.read(produtoRepositoryProvider),
      produtoOrigemId,
      produtoId,
    );
  }
}

final produtoDetailActionsProvider =
    Provider.family<ProdutoDetailActions, int>((ref, produtoId) {
  return ProdutoDetailActions(ref, produtoId);
});
