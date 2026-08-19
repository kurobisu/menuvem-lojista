import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/categoria_insumo.dart';
import '../domain/model/insumo.dart';

const _table = 'insumos';

Insumo insumoFromRow(Map<String, dynamic> row) {
  return Insumo(
    id: row['id'] as int,
    nome: row['nome'] as String,
    unidadeCompra: row['unidade_compra'] as String,
    unidadeUso: row['unidade_uso'] as String,
    fatorConversao: (row['fator_conversao'] as num).toDouble(),
    custoAtual: (row['custo_atual'] as num? ?? 0).toDouble(),
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
    categoria: CategoriaInsumo.values.firstWhere(
      (c) => c.name.toUpperCase() == (row['categoria'] as String? ?? 'INSUMO'),
      orElse: () => CategoriaInsumo.insumo,
    ),
    emoji: row['emoji'] as String?,
  );
}

Map<String, dynamic> _insumoToInsertRow(Insumo insumo) {
  return {
    'nome': insumo.nome,
    'unidade_compra': insumo.unidadeCompra,
    'unidade_uso': insumo.unidadeUso,
    'fator_conversao': insumo.fatorConversao,
    'custo_atual': insumo.custoAtual,
    'categoria': insumo.categoria.name.toUpperCase(),
    'emoji': insumo.emoji,
  };
}

class InsumoRepository {
  InsumoRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Insumo>> getAllInsumos() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('nome')
        .map((rows) => rows.map(insumoFromRow).toList());
  }

  Stream<List<Insumo>> searchInsumos(String query) {
    return getAllInsumos().map((list) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return list;
      return list.where((i) => i.nome.toLowerCase().contains(q)).toList();
    });
  }

  Future<Insumo?> getInsumoById(int id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : insumoFromRow(row);
  }

  Future<int> insertInsumo(Insumo insumo) async {
    final row = await _client
        .from(_table)
        .insert(_insumoToInsertRow(insumo))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateInsumo(Insumo insumo) {
    return _client.from(_table).update(_insumoToInsertRow(insumo)).eq(
          'id',
          insumo.id,
        );
  }

  Future<void> updateCustoInsumo(int id, double novoCusto) {
    return _client.from(_table).update({'custo_atual': novoCusto}).eq(
          'id',
          id,
        );
  }

  Future<void> deleteInsumo(Insumo insumo) {
    return _client.from(_table).delete().eq('id', insumo.id);
  }
}
