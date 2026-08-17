import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/componente.dart';
import '../domain/model/item_componente.dart';
import '../domain/model/tipo_componente.dart';

const _tableComponentes = 'componentes';
const _tableItens = 'itens_componente';

Componente componenteFromRow(Map<String, dynamic> row) {
  return Componente(
    id: row['id'] as int,
    nome: row['nome'] as String,
    tipo: TipoComponente.values.firstWhere(
      (t) => t.name.toUpperCase() == (row['tipo'] as String? ?? 'OUTRO'),
      orElse: () => TipoComponente.outro,
    ),
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

Map<String, dynamic> _componenteToInsertRow(Componente c) {
  return {'nome': c.nome, 'tipo': c.tipo.name.toUpperCase()};
}

ItemComponente _itemComponenteFromRow(Map<String, dynamic> row) {
  return ItemComponente(
    id: row['id'] as int,
    componenteId: row['componente_id'] as int,
    insumoId: row['insumo_id'] as int,
    quantidade: (row['quantidade'] as num).toDouble(),
    perdaPercentual: (row['perda_percentual'] as num? ?? 0).toDouble(),
  );
}

Map<String, dynamic> _itemComponenteToInsertRow(ItemComponente item) {
  return {
    'componente_id': item.componenteId,
    'insumo_id': item.insumoId,
    'quantidade': item.quantidade,
    'perda_percentual': item.perdaPercentual,
  };
}

class ComponenteRepository {
  ComponenteRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Componente>> getAllComponentes() {
    return _client
        .from(_tableComponentes)
        .stream(primaryKey: ['id'])
        .order('nome')
        .map((rows) => rows.map(componenteFromRow).toList());
  }

  Stream<List<ItemComponente>> getAllItensComponente() {
    return _client
        .from(_tableItens)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_itemComponenteFromRow).toList());
  }

  Stream<List<ItemComponente>> getItensByComponente(int componenteId) {
    return _client
        .from(_tableItens)
        .stream(primaryKey: ['id'])
        .eq('componente_id', componenteId)
        .map((rows) => rows.map(_itemComponenteFromRow).toList());
  }

  Future<Componente?> getComponenteById(int id) async {
    final row = await _client
        .from(_tableComponentes)
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : componenteFromRow(row);
  }

  Future<int> insertComponente(Componente componente) async {
    final row = await _client
        .from(_tableComponentes)
        .insert(_componenteToInsertRow(componente))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateComponente(Componente componente) {
    return _client
        .from(_tableComponentes)
        .update(_componenteToInsertRow(componente))
        .eq('id', componente.id);
  }

  Future<void> deleteComponente(Componente componente) {
    return _client.from(_tableComponentes).delete().eq('id', componente.id);
  }

  Future<int> insertItemComponente(ItemComponente item) async {
    final row = await _client
        .from(_tableItens)
        .insert(_itemComponenteToInsertRow(item))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateItemComponente(ItemComponente item) {
    return _client.from(_tableItens).update({
      'quantidade': item.quantidade,
      'perda_percentual': item.perdaPercentual,
    }).eq('id', item.id);
  }

  Future<void> deleteItemComponente(ItemComponente item) {
    return _client.from(_tableItens).delete().eq('id', item.id);
  }

  Future<void> deleteItensByComponente(int componenteId) {
    return _client
        .from(_tableItens)
        .delete()
        .eq('componente_id', componenteId);
  }

  Future<List<ItemComponente>> getItensByInsumo(int insumoId) async {
    final rows =
        await _client.from(_tableItens).select().eq('insumo_id', insumoId);
    return rows.map(_itemComponenteFromRow).toList();
  }
}
