import '../../data/historico_preco_repository.dart';
import '../model/tendencia_preco.dart';

/// Retorna a tendência de preço do insumo com base nas últimas 3 compras.
Future<TendenciaPreco> getTendenciaPreco(
  HistoricoPrecoRepository repository,
  int insumoId,
) async {
  final ultimos = await repository.getUltimosPrecos(insumoId, 3);
  final precos = ultimos.map((h) => h.preco).toList();
  return TendenciaPreco.calcular(precos);
}
