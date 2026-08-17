import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/model/insumo.dart';
import '../../domain/model/item_lista.dart';
import '../../domain/model/lista_compras.dart';
import '../../domain/model/tendencia_preco.dart';
import '../../domain/usecase/lista_compras_usecases.dart' as usecase;
import '../../domain/usecase/tendencia_usecase.dart';
import '../../providers/repository_providers.dart';

class ShoppingListData {
  final ListaCompras? lista;
  final List<ItemLista> itens;
  final Map<int, TendenciaPreco> tendencias;

  const ShoppingListData({this.lista, required this.itens, required this.tendencias});

  double get totalGasto =>
      itens.where((i) => i.comprado).fold(0.0, (s, i) => s + i.precoTotal);
  int get itensComprados => itens.where((i) => i.comprado).length;
  int get totalItens => itens.length;
}

final shoppingListDataProvider =
    StreamProvider.family<ShoppingListData, int>((ref, listaId) {
  final listaRepo = ref.watch(listaComprasRepositoryProvider);
  final historicoRepo = ref.watch(historicoPrecoRepositoryProvider);

  return Rx.combineLatest2(
    listaRepo.getListaById(listaId),
    listaRepo.getItensByLista(listaId),
    (lista, itens) => (lista, itens),
  ).asyncMap((tuple) async {
    final (lista, itens) = tuple;
    final insumoIds = itens.map((i) => i.insumoId).whereType<int>().toSet();
    final tendencias = <int, TendenciaPreco>{};
    for (final id in insumoIds) {
      try {
        tendencias[id] = await getTendenciaPreco(historicoRepo, id);
      } catch (_) {
        tendencias[id] = TendenciaPreco.estavel;
      }
    }
    return ShoppingListData(lista: lista, itens: itens, tendencias: tendencias);
  });
});

final insumoSearchProvider =
    StreamProvider.autoDispose.family<List<Insumo>, String>((ref, query) {
  if (query.trim().isEmpty) return Stream.value(const []);
  return ref
      .watch(insumoRepositoryProvider)
      .searchInsumos(query)
      .debounceTime(const Duration(milliseconds: 300));
});

class ShoppingListActions {
  ShoppingListActions(this.ref, this.listaId);
  final Ref ref;
  final int listaId;

  Future<void> addItem({
    required String nomeItem,
    required double quantidade,
    required String unidade,
    double precoUnitario = 0.0,
    Insumo? insumo,
  }) {
    return usecase.addItemToLista(
      ref.read(listaComprasRepositoryProvider),
      listaId: listaId,
      nomeItem: nomeItem,
      quantidade: quantidade,
      unidade: unidade,
      precoUnitario: precoUnitario,
      insumo: insumo,
    );
  }

  Future<void> toggleItem(int itemId, bool comprado, double preco) {
    return ref
        .read(listaComprasRepositoryProvider)
        .toggleItemComprado(itemId, comprado, preco);
  }

  Future<void> deleteItem(ItemLista item) {
    return ref.read(listaComprasRepositoryProvider).deleteItem(item);
  }

  Future<void> finalizarCompra() {
    return usecase.finalizarCompra(
      listaId,
      listaRepository: ref.read(listaComprasRepositoryProvider),
      insumoRepository: ref.read(insumoRepositoryProvider),
      historicoRepository: ref.read(historicoPrecoRepositoryProvider),
    );
  }
}

final shoppingListActionsProvider =
    Provider.family<ShoppingListActions, int>((ref, listaId) {
  return ShoppingListActions(ref, listaId);
});
