import 'produto.dart';

/// Produto com o custo calculado a partir da ficha técnica, mais as regras
/// de precificação por margem-alvo.
class ProdutoComCusto {
  final Produto produto;
  final double custoTotal;
  final int quantidadeItens;

  const ProdutoComCusto({
    required this.produto,
    required this.custoTotal,
    required this.quantidadeItens,
  });

  /// Preço sugerido = custo ÷ (1 − margem/100). Zero se não houver custo.
  double get precoSugerido {
    if (custoTotal > 0 && produto.margemAlvoPercentual < 100.0) {
      return custoTotal / (1.0 - produto.margemAlvoPercentual / 100.0);
    }
    return 0.0;
  }

  /// Margem real sobre o preço de venda atual (%). Null se não há preço praticado.
  double? get margemRealPercentual {
    final preco = produto.precoVendaAtual;
    if (preco == null || preco <= 0) return null;
    return (preco - custoTotal) / preco * 100.0;
  }

  /// Verdadeiro quando há preço praticado e a margem real ficou abaixo da margem-alvo.
  bool get margemAbaixoDaMeta {
    final margem = margemRealPercentual;
    if (margem == null) return false;
    return margem < produto.margemAlvoPercentual;
  }
}
