import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/item_lista.dart';
import '../domain/model/lista_compras.dart';

const _tableListas = 'listas_compras';
const _tableItens = 'itens_lista';

ListaCompras listaComprasFromRow(Map<String, dynamic> row) {
  return ListaCompras(
    id: row['id'] as int,
    nome: row['nome'] as String,
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
    dataFinalizacao: row['data_finalizacao'] == null
        ? null
        : DateTime.parse(row['data_finalizacao'] as String),
    totalGasto: (row['total_gasto'] as num? ?? 0).toDouble(),
    status: StatusLista.values.firstWhere(
      (s) => s.name.toUpperCase() == (row['status'] as String? ?? 'ABERTA'),
      orElse: () => StatusLista.aberta,
    ),
  );
}

Map<String, dynamic> _listaToInsertRow(ListaCompras lista) {
  return {'nome': lista.nome};
}

ItemLista _itemListaFromRow(Map<String, dynamic> row) {
  return ItemLista(
    id: row['id'] as int,
    listaComprasId: row['lista_compras_id'] as int,
    insumoId: row['insumo_id'] as int?,
    nomeItem: row['nome_item'] as String,
    quantidade: (row['quantidade'] as num).toDouble(),
    unidade: row['unidade'] as String,
    precoUnitario: (row['preco_unitario'] as num? ?? 0).toDouble(),
    comprado: row['comprado'] as bool? ?? false,
  );
}

Map<String, dynamic> _itemListaToInsertRow(ItemLista item) {
  return {
    'lista_compras_id': item.listaComprasId,
    'insumo_id': item.insumoId,
    'nome_item': item.nomeItem,
    'quantidade': item.quantidade,
    'unidade': item.unidade,
    'preco_unitario': item.precoUnitario,
    'comprado': item.comprado,
  };
}

class ListaComprasRepository {
  ListaComprasRepository(this._client);

  final SupabaseClient _client;

  Stream<List<ListaCompras>> getAllListas() {
    return _client
        .from(_tableListas)
        .stream(primaryKey: ['id'])
        .order('data_criacao')
        .map((rows) => rows.reversed.map(listaComprasFromRow).toList());
  }

  Stream<ListaCompras?> getListaById(int id) {
    return getAllListas().map(
      (list) => list.where((l) => l.id == id).firstOrNull,
    );
  }

  Future<int> insertLista(ListaCompras lista) async {
    final row = await _client
        .from(_tableListas)
        .insert(_listaToInsertRow(lista))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateLista(ListaCompras lista) async {
    await _client
        .from(_tableListas)
        .update({
          'nome': lista.nome,
          'status': lista.status.name.toUpperCase(),
          'total_gasto': lista.totalGasto,
          'data_finalizacao': lista.dataFinalizacao?.toUtc().toIso8601String(),
        })
        .eq('id', lista.id);
  }

  Future<void> deleteLista(ListaCompras lista) async {
    await _client.from(_tableListas).delete().eq('id', lista.id);
  }

  // ── Itens ────────────────────────────────────────────────────────────────

  Stream<List<ItemLista>> getItensByLista(int listaId) {
    return _client
        .from(_tableItens)
        .stream(primaryKey: ['id'])
        .eq('lista_compras_id', listaId)
        .order('id')
        .map((rows) => rows.map(_itemListaFromRow).toList());
  }

  Future<int> insertItem(ItemLista item) async {
    final row = await _client
        .from(_tableItens)
        .insert(_itemListaToInsertRow(item))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateItem(ItemLista item) async {
    await _client
        .from(_tableItens)
        .update(_itemListaToInsertRow(item))
        .eq('id', item.id);
  }

  Future<void> deleteItem(ItemLista item) async {
    await _client.from(_tableItens).delete().eq('id', item.id);
  }

  Future<void> toggleItemComprado(
    int itemId,
    bool comprado,
    double precoUnitario,
  ) async {
    await _client
        .from(_tableItens)
        .update({'comprado': comprado, 'preco_unitario': precoUnitario})
        .eq('id', itemId);
  }
}
