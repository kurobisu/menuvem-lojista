import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/item_ficha_tecnica.dart';
import '../domain/model/porcao.dart';
import '../domain/model/produto.dart';
import '../domain/model/produto_componente.dart';

const _tableProdutos = 'produtos';
const _tablePorcoes = 'porcoes';
const _tableFicha = 'itens_ficha_tecnica';
const _tableProdutoComponentes = 'produto_componentes';

Produto produtoFromRow(Map<String, dynamic> row) {
  return Produto(
    id: row['id'] as int,
    nome: row['nome'] as String,
    emoji: row['emoji'] as String?,
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

Map<String, dynamic> _produtoToInsertRow(Produto produto) {
  return {'nome': produto.nome, 'emoji': produto.emoji};
}

Porcao porcaoFromRow(Map<String, dynamic> row) {
  return Porcao(
    id: row['id'] as int,
    produtoId: row['produto_id'] as int,
    nome: row['nome'] as String,
    ordem: (row['ordem'] as num? ?? 0).toInt(),
    margemAlvoPercentual: (row['margem_alvo_percentual'] as num).toDouble(),
    precoVendaAtual: (row['preco_venda_atual'] as num?)?.toDouble(),
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

/// Remove linhas repetidas mantendo a ordem. O `.stream()` do Supabase pode
/// entregar a mesma linha duas vezes logo após um insert (o fetch inicial e o
/// evento de INSERT do Realtime chegam quase juntos) — sem isso, a porção ou
/// o insumo recém-criado aparecia duplicado na tela até recarregar.
List<T> _dedupePorId<T>(List<T> itens, int Function(T) idDe) {
  final vistos = <int>{};
  return [
    for (final item in itens)
      if (vistos.add(idDe(item))) item,
  ];
}

Map<String, dynamic> _porcaoToInsertRow(Porcao porcao) {
  return {
    'produto_id': porcao.produtoId,
    'nome': porcao.nome,
    'ordem': porcao.ordem,
    'margem_alvo_percentual': porcao.margemAlvoPercentual,
    'preco_venda_atual': porcao.precoVendaAtual,
  };
}

ItemFichaTecnica _itemFichaFromRow(Map<String, dynamic> row) {
  return ItemFichaTecnica(
    id: row['id'] as int,
    porcaoId: row['porcao_id'] as int,
    insumoId: row['insumo_id'] as int,
    quantidade: (row['quantidade'] as num).toDouble(),
    perdaPercentual: (row['perda_percentual'] as num? ?? 0).toDouble(),
  );
}

Map<String, dynamic> _itemFichaToInsertRow(ItemFichaTecnica item) {
  return {
    'porcao_id': item.porcaoId,
    'insumo_id': item.insumoId,
    'quantidade': item.quantidade,
    'perda_percentual': item.perdaPercentual,
  };
}

ProdutoComponente _produtoComponenteFromRow(Map<String, dynamic> row) {
  return ProdutoComponente(
    id: row['id'] as int,
    porcaoId: row['porcao_id'] as int,
    componenteId: row['componente_id'] as int,
    tamanhoComponenteId: row['tamanho_componente_id'] as int,
    multiplicador: (row['multiplicador'] as num).toDouble(),
  );
}

Map<String, dynamic> _produtoComponenteToInsertRow(ProdutoComponente v) {
  return {
    'porcao_id': v.porcaoId,
    'componente_id': v.componenteId,
    'tamanho_componente_id': v.tamanhoComponenteId,
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
    final row = await _client
        .from(_tableProdutos)
        .select()
        .eq('id', id)
        .maybeSingle();
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

  Future<void> updateProduto(Produto produto) async {
    await _client
        .from(_tableProdutos)
        .update(_produtoToInsertRow(produto))
        .eq('id', produto.id);
  }

  Future<void> deleteProduto(Produto produto) async {
    await _client.from(_tableProdutos).delete().eq('id', produto.id);
  }

  // ── Porções ──────────────────────────────────────────────────────────────

  Stream<List<Porcao>> getPorcoesByProduto(int produtoId) {
    return _client
        .from(_tablePorcoes)
        .stream(primaryKey: ['id'])
        .eq('produto_id', produtoId)
        .order('ordem')
        .map(
          (rows) => _dedupePorId(rows.map(porcaoFromRow).toList(), (p) => p.id),
        );
  }

  Stream<List<Porcao>> getAllPorcoes() {
    return _client
        .from(_tablePorcoes)
        .stream(primaryKey: ['id'])
        .order('ordem')
        .map(
          (rows) => _dedupePorId(rows.map(porcaoFromRow).toList(), (p) => p.id),
        );
  }

  Future<List<Porcao>> getPorcoesByProdutoOnce(int produtoId) async {
    final rows = await _client
        .from(_tablePorcoes)
        .select()
        .eq('produto_id', produtoId)
        .order('ordem');
    return rows.map(porcaoFromRow).toList();
  }

  Future<int> insertPorcao(Porcao porcao) async {
    final row = await _client
        .from(_tablePorcoes)
        .insert(_porcaoToInsertRow(porcao))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updatePorcao(Porcao porcao) async {
    await _client
        .from(_tablePorcoes)
        .update(_porcaoToInsertRow(porcao))
        .eq('id', porcao.id);
  }

  Future<void> deletePorcao(Porcao porcao) async {
    await _client.from(_tablePorcoes).delete().eq('id', porcao.id);
  }

  /// Grava a nova ordem das porções. Mesmo idiom de `updateOrdensComponentes`:
  /// N updates independentes em paralelo (não há batch no PostgREST).
  Future<void> updateOrdensPorcoes(Map<int, int> ordemPorId) async {
    await Future.wait([
      for (final entry in ordemPorId.entries)
        _client
            .from(_tablePorcoes)
            .update({'ordem': entry.value})
            .eq('id', entry.key),
    ]);
  }

  // ── Ficha técnica (itens avulsos da porção) ─────────────────────────────

  Stream<List<ItemFichaTecnica>> getItensFichaByPorcao(int porcaoId) {
    return _client
        .from(_tableFicha)
        .stream(primaryKey: ['id'])
        .eq('porcao_id', porcaoId)
        .map(
          (rows) =>
              _dedupePorId(rows.map(_itemFichaFromRow).toList(), (i) => i.id),
        );
  }

  Stream<List<ItemFichaTecnica>> getAllItensFicha() {
    return _client
        .from(_tableFicha)
        .stream(primaryKey: ['id'])
        .map(
          (rows) =>
              _dedupePorId(rows.map(_itemFichaFromRow).toList(), (i) => i.id),
        );
  }

  Future<List<ItemFichaTecnica>> getItensFichaByPorcaoOnce(int porcaoId) async {
    final rows = await _client
        .from(_tableFicha)
        .select()
        .eq('porcao_id', porcaoId);
    return rows.map(_itemFichaFromRow).toList();
  }

  Future<List<ItemFichaTecnica>> getItensFichaByInsumo(int insumoId) async {
    final rows = await _client
        .from(_tableFicha)
        .select()
        .eq('insumo_id', insumoId);
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

  Future<void> updateItemFicha(ItemFichaTecnica item) async {
    await _client
        .from(_tableFicha)
        .update({
          'quantidade': item.quantidade,
          'perda_percentual': item.perdaPercentual,
        })
        .eq('id', item.id);
  }

  Future<void> deleteItemFicha(ItemFichaTecnica item) async {
    await _client.from(_tableFicha).delete().eq('id', item.id);
  }

  Future<void> deleteItensFichaByPorcao(int porcaoId) async {
    await _client.from(_tableFicha).delete().eq('porcao_id', porcaoId);
  }

  // ── Componentes aplicados à porção (produto_componentes) ────────────────

  Stream<List<ProdutoComponente>> getProdutoComponentesByPorcao(int porcaoId) {
    return _client
        .from(_tableProdutoComponentes)
        .stream(primaryKey: ['id'])
        .eq('porcao_id', porcaoId)
        .map(
          (rows) => _dedupePorId(
            rows.map(_produtoComponenteFromRow).toList(),
            (v) => v.id,
          ),
        );
  }

  Stream<List<ProdutoComponente>> getAllProdutoComponentes() {
    return _client
        .from(_tableProdutoComponentes)
        .stream(primaryKey: ['id'])
        .map(
          (rows) => _dedupePorId(
            rows.map(_produtoComponenteFromRow).toList(),
            (v) => v.id,
          ),
        );
  }

  Future<List<ProdutoComponente>> getProdutoComponentesByPorcaoOnce(
    int porcaoId,
  ) async {
    final rows = await _client
        .from(_tableProdutoComponentes)
        .select()
        .eq('porcao_id', porcaoId);
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

  Future<void> updateProdutoComponente(ProdutoComponente vinculo) async {
    await _client
        .from(_tableProdutoComponentes)
        .update({'multiplicador': vinculo.multiplicador})
        .eq('id', vinculo.id);
  }

  Future<void> deleteProdutoComponente(ProdutoComponente vinculo) async {
    await _client.from(_tableProdutoComponentes).delete().eq('id', vinculo.id);
  }

  Future<void> deleteProdutoComponentesByPorcao(int porcaoId) async {
    await _client
        .from(_tableProdutoComponentes)
        .delete()
        .eq('porcao_id', porcaoId);
  }
}
