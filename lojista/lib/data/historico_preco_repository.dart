import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/historico_preco.dart';

const _table = 'historico_precos';

HistoricoPreco _historicoFromRow(Map<String, dynamic> row) {
  return HistoricoPreco(
    id: row['id'] as int,
    insumoId: row['insumo_id'] as int,
    preco: (row['preco'] as num).toDouble(),
    data: DateTime.parse(row['data'] as String),
    listaComprasId: row['lista_compras_id'] as int,
    listaComprasNome: row['lista_compras_nome'] as String? ?? '',
  );
}

Map<String, dynamic> _historicoToInsertRow(HistoricoPreco h) {
  return {
    'insumo_id': h.insumoId,
    'preco': h.preco,
    'lista_compras_id': h.listaComprasId,
    'lista_compras_nome': h.listaComprasNome,
  };
}

class HistoricoPrecoRepository {
  HistoricoPrecoRepository(this._client);

  final SupabaseClient _client;

  Stream<List<HistoricoPreco>> getHistoricoByInsumo(int insumoId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('insumo_id', insumoId)
        .order('data')
        .map((rows) => rows.map(_historicoFromRow).toList());
  }

  Stream<List<int>> getAllInsumosComHistorico() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows.map((r) => r['insumo_id'] as int).toSet().toList(),
        );
  }

  Future<int> insertHistorico(HistoricoPreco historico) async {
    final row = await _client
        .from(_table)
        .insert(_historicoToInsertRow(historico))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<List<HistoricoPreco>> getUltimosPrecos(
    int insumoId,
    int limite,
  ) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('insumo_id', insumoId)
        .order('data', ascending: false)
        .limit(limite);
    return rows.map(_historicoFromRow).toList();
  }
}
