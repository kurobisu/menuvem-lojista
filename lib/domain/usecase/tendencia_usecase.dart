import '../../data/historico_preco_repository.dart';
import '../model/tendencia_preco.dart';

/// Retorna a tendência de preço do insumo com base nas últimas 3 compras.
Future<TendenciaPreco> getTendenciaPreco(
  HistoricoPrecoRepository repository,
  int insumoId,
) async {
  final ultimos = await repository.getUltimosPrecos(insumoId, 3);
  // getUltimosPrecos devolve do mais recente para o mais antigo, mas
  // TendenciaPreco.calcular espera o contrário — sem inverter aqui, a
  // tendência sai trocada (preço que subiu aparece como queda).
  final precos = ultimos.reversed.map((h) => h.preco).toList();
  return TendenciaPreco.calcular(precos);
}

/// Tendência de **todos** os insumos de uma vez, numa única query.
///
/// Use esta função em telas que mostram tendência de uma lista de insumos
/// (Home, Histórico de Preços); chamar [getTendenciaPreco] em laço faz uma
/// ida ao servidor por insumo e trava a UI.
Future<Map<int, TendenciaPreco>> getTendenciasPorInsumo(
  HistoricoPrecoRepository repository,
) async {
  final porInsumo = await repository.getUltimosPrecosPorInsumo(3);
  return porInsumo.map(
    (insumoId, historico) => MapEntry(
      insumoId,
      TendenciaPreco.calcular(historico.map((h) => h.preco).toList()),
    ),
  );
}
