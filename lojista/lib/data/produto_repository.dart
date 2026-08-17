import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/item_ficha_tecnica.dart';
import '../domain/model/produto.dart';
import '../domain/model/produto_componente.dart';

const _tableProdutos = 'produtos';
const _tableFicha = 'itens_ficha_tecnica';
const _tableProdutoComponentes = 'produto_componentes';

Produto produtoFromRow(Map<String, dynamic> row) {
  return Produto(
    id: row['id'] as int,
    nome: row['nome'] as String,
    margemAlvoPercentual: (row['margem_alvo_percentual'] as num).toDouble(),
    precoVendaAtual: (row['preco_venda_atual'] as num?)?.toDouble(),
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

Map<String, dynamic> _produtoToInsertRow(Produto produto) {
  return {
    'nome': produto.nome,
    'margem_alvo_percentual': produto.margemAlvoPercentual,
    'preco_venda_atual': produto.precoVendaAtual,
  };
}

ItemFichaTecnica _itemFichaFromRow(Map<String, dynamic> row) {
  return ItemFichaTecnica(
    id: row['id'] as int,
    produtoId: row['produto_id'] as int,
    insumoId: row['insumo_id'] as int,
    quantidade: (row['quantidade'] as num).toDouble(),
    perdaPercentual: (row['perda_percentual'] as num? ?? 0).toDouble(),
  );
}

Map<String, dynamic> _itemFichaToInsertRow(ItemFichaTecnica item) {
  return {
    'produto_id': item.produtoId,
    'insumo_id': item.insumoId,
    'quantidade': item.quantidade,
    'perda_percentual': item.perdaPercentual,
  };
}

ProdutoComponente _produtoComponenteFromRow(Map<String, dynamic> row) {
  return ProdutoComponente(
    id: row['id'] as int,
    produtoId: row['produto_id'] as int,
    componenteId: row['componente_id'] as int,
    multiplicador: (row['multiplicador'] as num).toDouble(),
  );
}

Map<String, dynamic> _produtoComponenteToInsertRow(ProdutoComponente v) {
  return {
    'produto_id': v.produtoId,
    'componente_id': v.componenteId,
    'multiplicador': v.multiplicador,
  };
}

class ProdutoRepository {
  ProdutoRepository(this._client);

  final SupabaseClient _client;

  // ── Produtos ─────────────────────────────────────────────────────────────

  Stream<List<Produto>> getAllProdutos() {
    return _client
        .from(_tableProdutos)
        .stream(primaryKey: ['id'])
        .order('nome')
        .map((rows) => rows.map(produtoFromRow).toList());
  }

  Future<Produto?> getProdutoById(int id) async {
    final row =
        await _client.from(_tableProdutos).select().eq('id', id).maybeSingle();
    return row == null ? null : produtoFromRow(row);
  }

  Future<int> insertProduto(Produto produto) async {
    final row = await _client
        .from(_tableProdutos)
        .insert(_produtoToInsertRow(produto))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateProduto(Produto produto) {
    return _client
        .from(_tableProdutos)
        .update(_produtoToInsertRow(produto))
        .eq('id', produto.id);
  }

  Future<void> deleteProduto(Produto produto) {
    return _client.from(_tableProdutos).delete().eq('id', produto.id);
  }

  // ── Ficha técnica (itens avulsos) ───────────────────────────────────────

  Stream<List<ItemFichaTecnica>> getItensFichaByProduto(int produtoId) {
    return _client
        .from(_tableFicha)
        .stream(primaryKey: ['id'])
        .eq('produto_id', produtoId)
        .map((rows) => rows.map(_itemFichaFromRow).toList());
  }

  Stream<List<ItemFichaTecnica>> getAllItensFicha() {
    return _client
        .from(_tableFicha)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_itemFichaFromRow).toList());
  }

  Future<List<ItemFichaTecnica>> getItensFichaByInsumo(int insumoId) async {
    final rows =
        await _client.from(_tableFicha).select().eq('insumo_id', insumoId);
    return rows.map(_itemFichaFromRow).toList();
  }

  Future<int> insertItemFicha(ItemFichaTecnica item) async {
    final row = await _client
        .from(_tableFicha)
        .insert(_itemFichaToInsertRow(item))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateItemFicha(ItemFichaTecnica item) {
    return _client.from(_tableFicha).update({
      'quantidade': item.quantidade,
      'perda_percentual': item.perdaPercentual,
    }).eq('id', item.id);
  }

  Future<void> deleteItemFicha(ItemFichaTecnica item) {
    return _client.from(_tableFicha).delete().eq('id', item.id);
  }

  Future<void> deleteItensFichaByProduto(int produtoId) {
    return _client.from(_tableFicha).delete().eq('produto_id', produtoId);
  }

  // ── Componentes aplicados ao produto (produto_componentes) ─────────────

  Stream<List<ProdutoComponente>> getProdutoComponentesByProduto(
    int produtoId,
  ) {
    return _client
        .from(_tableProdutoComponentes)
        .stream(primaryKey: ['id'])
        .eq('produto_id', produtoId)
        .map((rows) => rows.map(_produtoComponenteFromRow).toList());
  }

  Stream<List<ProdutoComponente>> getAllProdutoComponentes() {
    return _client
        .from(_tableProdutoComponentes)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_produtoComponenteFromRow).toList());
  }

  Future<List<ProdutoComponente>> getProdutoComponentesByProdutoOnce(
    int produtoId,
  ) async {
    final rows = await _client
        .from(_tableProdutoComponentes)
        .select()
        .eq('produto_id', produtoId);
    return rows.map(_produtoComponenteFromRow).toList();
  }

  Future<int> insertProdutoComponente(ProdutoComponente vinculo) async {
    final row = await _client
        .from(_tableProdutoComponentes)
        .insert(_produtoComponenteToInsertRow(vinculo))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateProdutoComponente(ProdutoComponente vinculo) {
    return _client
        .from(_tableProdutoComponentes)
        .update({'multiplicador': vinculo.multiplicador}).eq(
      'id',
      vinculo.id,
    );
  }

  Future<void> deleteProdutoComponente(ProdutoComponente vinculo) {
    return _client
        .from(_tableProdutoComponentes)
        .delete()
        .eq('id', vinculo.id);
  }

  Future<void> deleteProdutoComponentesByProduto(int produtoId) {
    return _client
        .from(_tableProdutoComponentes)
        .delete()
        .eq('produto_id', produtoId);
  }
}
