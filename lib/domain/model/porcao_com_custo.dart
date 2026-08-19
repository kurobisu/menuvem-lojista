import 'porcao.dart';

/// Porção enriquecida com o custo calculado pela ficha técnica (insumos
/// soltos + componentes aplicados). O custo vem pronto do cost_engine.
class PorcaoComCusto {
  final Porcao porcao;
  final double custoTotal;
  final int quantidadeItens;

  const PorcaoComCusto({
    required this.porcao,
    required this.custoTotal,
    required this.quantidadeItens,
  });

  /// Preço que atinge a margem-alvo: custo / (1 − margem/100).
  double get precoSugerido {
    if (custoTotal > 0 && porcao.margemAlvoPercentual < 100.0) {
      return custoTotal / (1.0 - porcao.margemAlvoPercentual / 100.0);
    }
    return 0.0;
  }

  /// Margem real sobre o preço praticado, ou null se não há preço definido.
  double? get margemRealPercentual {
    final preco = porcao.precoVendaAtual;
    if (preco == null || preco <= 0) return null;
    return (preco - custoTotal) / preco * 100.0;
  }

  /// True quando há preço praticado e a margem real ficou abaixo da meta.
  bool get margemAbaixoDaMeta {
    final margem = margemRealPercentual;
    if (margem == null) return false;
    return margem < porcao.margemAlvoPercentual;
  }
}
