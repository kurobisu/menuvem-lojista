import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/model/componente.dart';
import '../domain/model/item_componente.dart';
import '../domain/model/tamanho_componente.dart';
import '../domain/model/tipo_componente.dart';

const _tableComponentes = 'componentes';
const _tableTamanhos = 'tamanhos_componente';
const _tableItens = 'itens_componente';
const _tableTipos = 'tipos_componente';

/// Remove linhas repetidas mantendo a ordem. O `.stream()` do Supabase pode
/// entregar a mesma linha duas vezes logo apos um insert (o fetch inicial e o
/// evento de INSERT do Realtime chegam quase juntos) -- sem isso, o insumo
/// recem-criado num componente aparecia duplicado na tela ate recarregar.
/// Mesmo padrao usado em produto_repository.dart.
List<T> _dedupePorId<T>(List<T> itens, int Function(T) idDe) {
  final vistos = <int>{};
  return [
    for (final item in itens)
      if (vistos.add(idDe(item))) item,
  ];
}

Componente componenteFromRow(Map<String, dynamic> row) {
  return Componente(
    id: row['id'] as int,
    nome: row['nome'] as String,
    tipoComponenteId: row['tipo_componente_id'] as int?,
    ordem: (row['ordem'] as num? ?? 0).toInt(),
    emoji: row['emoji'] as String?,
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

Map<String, dynamic> _componenteToInsertRow(Componente c) {
  return {
    'nome': c.nome,
    'tipo_componente_id': c.tipoComponenteId,
    'ordem': c.ordem,
    'emoji': c.emoji,
  };
}

TamanhoComponente _tamanhoComponenteFromRow(Map<String, dynamic> row) {
  return TamanhoComponente(
    id: row['id'] as int,
    componenteId: row['componente_id'] as int,
    nome: row['nome'] as String,
    ordem: (row['ordem'] as num? ?? 0).toInt(),
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

Map<String, dynamic> _tamanhoComponenteToInsertRow(TamanhoComponente t) {
  return {'componente_id': t.componenteId, 'nome': t.nome, 'ordem': t.ordem};
}

ItemComponente _itemComponenteFromRow(Map<String, dynamic> row) {
  return ItemComponente(
    id: row['id'] as int,
    tamanhoComponenteId: row['tamanho_componente_id'] as int,
    insumoId: row['insumo_id'] as int,
    quantidade: (row['quantidade'] as num).toDouble(),
    perdaPercentual: (row['perda_percentual'] as num? ?? 0).toDouble(),
  );
}

Map<String, dynamic> _itemComponenteToInsertRow(ItemComponente item) {
  return {
    'tamanho_componente_id': item.tamanhoComponenteId,
    'insumo_id': item.insumoId,
    'quantidade': item.quantidade,
    'perda_percentual': item.perdaPercentual,
  };
}

TipoComponente _tipoComponenteFromRow(Map<String, dynamic> row) {
  return TipoComponente(
    id: row['id'] as int,
    nome: row['nome'] as String,
    ordem: (row['ordem'] as num? ?? 0).toInt(),
    dataCriacao: DateTime.parse(row['data_criacao'] as String),
  );
}

class ComponenteRepository {
  ComponenteRepository(this._client);

  final SupabaseClient _client;

  // ── Componentes ────────────────────────────────────────────────────────

  Stream<List<Componente>> getAllComponentes() {
    return _client
        .from(_tableComponentes)
        .stream(primaryKey: ['id'])
        .order('ordem')
        .map(
          (rows) => _dedupePorId(
            rows.map(componenteFromRow).toList(),
            (c) => c.id,
          ),
        );
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

  Future<void> updateComponente(Componente componente) async {
    await _client
        .from(_tableComponentes)
        .update(_componenteToInsertRow(componente))
        .eq('id', componente.id);
  }

  Future<void> deleteComponente(Componente componente) async {
    await _client.from(_tableComponentes).delete().eq('id', componente.id);
  }

  /// Grava a nova ordem de exibição de vários componentes de uma vez (tela
  /// de Componentes, arrastar-e-soltar com o filtro "Todos" ativo).
  Future<void> updateOrdensComponentes(Map<int, int> ordemPorId) {
    return Future.wait(
      ordemPorId.entries.map(
        (e) => _client
            .from(_tableComponentes)
            .update({'ordem': e.value})
            .eq('id', e.key),
      ),
    );
  }

  // ── Tamanhos de um componente ─────────────────────────────────────────

  Stream<List<TamanhoComponente>> getAllTamanhosComponente() {
    return _client
        .from(_tableTamanhos)
        .stream(primaryKey: ['id'])
        .order('ordem')
        .map(
          (rows) => _dedupePorId(
            rows.map(_tamanhoComponenteFromRow).toList(),
            (t) => t.id,
          ),
        );
  }

  Stream<List<TamanhoComponente>> getTamanhosByComponente(int componenteId) {
    return _client
        .from(_tableTamanhos)
        .stream(primaryKey: ['id'])
        .eq('componente_id', componenteId)
        .order('ordem')
        .map(
          (rows) => _dedupePorId(
            rows.map(_tamanhoComponenteFromRow).toList(),
            (t) => t.id,
          ),
        );
  }

  Future<List<TamanhoComponente>> getTamanhosByComponenteOnce(
    int componenteId,
  ) async {
    final rows = await _client
        .from(_tableTamanhos)
        .select()
        .eq('componente_id', componenteId)
        .order('ordem');
    return rows.map(_tamanhoComponenteFromRow).toList();
  }

  Future<int> insertTamanho(TamanhoComponente tamanho) async {
    final row = await _client
        .from(_tableTamanhos)
        .insert(_tamanhoComponenteToInsertRow(tamanho))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateTamanho(TamanhoComponente tamanho) async {
    await _client
        .from(_tableTamanhos)
        .update(_tamanhoComponenteToInsertRow(tamanho))
        .eq('id', tamanho.id);
  }

  Future<void> deleteTamanho(TamanhoComponente tamanho) async {
    await _client.from(_tableTamanhos).delete().eq('id', tamanho.id);
  }

  /// Grava a nova ordem de exibição dos tamanhos de um componente de uma vez
  /// (arrastar-e-soltar na barra de tamanhos).
  Future<void> updateOrdensTamanhos(Map<int, int> ordemPorId) {
    return Future.wait(
      ordemPorId.entries.map(
        (e) => _client
            .from(_tableTamanhos)
            .update({'ordem': e.value})
            .eq('id', e.key),
      ),
    );
  }

  // ── Itens de um tamanho ────────────────────────────────────────────────

  Stream<List<ItemComponente>> getAllItensComponente() {
    return _client
        .from(_tableItens)
        .stream(primaryKey: ['id'])
        .map(
          (rows) => _dedupePorId(
            rows.map(_itemComponenteFromRow).toList(),
            (i) => i.id,
          ),
        );
  }

  Stream<List<ItemComponente>> getItensByTamanho(int tamanhoComponenteId) {
    return _client
        .from(_tableItens)
        .stream(primaryKey: ['id'])
        .eq('tamanho_componente_id', tamanhoComponenteId)
        .map(
          (rows) => _dedupePorId(
            rows.map(_itemComponenteFromRow).toList(),
            (i) => i.id,
          ),
        );
  }

  Future<List<ItemComponente>> getItensByTamanhoOnce(
    int tamanhoComponenteId,
  ) async {
    final rows = await _client
        .from(_tableItens)
        .select()
        .eq('tamanho_componente_id', tamanhoComponenteId);
    return rows.map(_itemComponenteFromRow).toList();
  }

  Future<int> insertItemComponente(ItemComponente item) async {
    final row = await _client
        .from(_tableItens)
        .insert(_itemComponenteToInsertRow(item))
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> updateItemComponente(ItemComponente item) async {
    await _client
        .from(_tableItens)
        .update({
          'quantidade': item.quantidade,
          'perda_percentual': item.perdaPercentual,
        })
        .eq('id', item.id);
  }

  Future<void> deleteItemComponente(ItemComponente item) async {
    await _client.from(_tableItens).delete().eq('id', item.id);
  }

  Future<void> deleteItensByTamanho(int tamanhoComponenteId) async {
    await _client
        .from(_tableItens)
        .delete()
        .eq('tamanho_componente_id', tamanhoComponenteId);
  }

  Future<List<ItemComponente>> getItensByInsumo(int insumoId) async {
    final rows = await _client
        .from(_tableItens)
        .select()
        .eq('insumo_id', insumoId);
    return rows.map(_itemComponenteFromRow).toList();
  }

  // ── Tipos de componente ──────────────────────────────────────────────

  Stream<List<TipoComponente>> getAllTipos() {
    return _client
        .from(_tableTipos)
        .stream(primaryKey: ['id'])
        .order('ordem')
        .map((rows) => rows.map(_tipoComponenteFromRow).toList());
  }

  Future<List<TipoComponente>> getTiposOnce() async {
    final rows = await _client.from(_tableTipos).select();
    return rows.map(_tipoComponenteFromRow).toList();
  }

  Future<int> insertTipo(String nome, {int ordem = 0}) async {
    final row = await _client
        .from(_tableTipos)
        .insert({'nome': nome, 'ordem': ordem})
        .select()
        .single();
    return row['id'] as int;
  }

  Future<void> deleteTipo(int id) async {
    await _client.from(_tableTipos).delete().eq('id', id);
  }

  /// Grava a nova ordem de vários tipos de componente de uma vez (tela de
  /// reordenar tipos).
  Future<void> updateOrdensTipos(Map<int, int> ordemPorId) {
    return Future.wait(
      ordemPorId.entries.map(
        (e) => _client
            .from(_tableTipos)
            .update({'ordem': e.value})
            .eq('id', e.key),
      ),
    );
  }
}
