import 'porcao_com_custo.dart';
import 'produto.dart';

/// Produto com todas as suas porções já custeadas. Um produto sempre tem
/// pelo menos uma porção; quando tem só uma, a UI a trata como o produto
/// inteiro e não mostra nada sobre porções.
class ProdutoComCusto {
  final Produto produto;
  final List<PorcaoComCusto> porcoes;

  const ProdutoComCusto({required this.produto, required this.porcoes});

  bool get temMultiplasPorcoes => porcoes.length > 1;

  /// Porção usada para representar o produto em listagens compactas.
  /// Null só no caso degenerado de um produto sem nenhuma porção (dado
  /// inconsistente — a UI trata mostrando o produto sem custo).
  PorcaoComCusto? get porcaoPrincipal => porcoes.isEmpty ? null : porcoes.first;

  double get custoMinimo => porcoes.isEmpty
      ? 0.0
      : porcoes.map((p) => p.custoTotal).reduce((a, b) => a < b ? a : b);

  double get custoMaximo => porcoes.isEmpty
      ? 0.0
      : porcoes.map((p) => p.custoTotal).reduce((a, b) => a > b ? a : b);

  double get precoSugeridoMinimo => porcoes.isEmpty
      ? 0.0
      : porcoes.map((p) => p.precoSugerido).reduce((a, b) => a < b ? a : b);

  double get precoSugeridoMaximo => porcoes.isEmpty
      ? 0.0
      : porcoes.map((p) => p.precoSugerido).reduce((a, b) => a > b ? a : b);

  /// Porções cujo preço praticado ficou abaixo da margem-alvo — alimenta os
  /// alertas de margem da Home.
  List<PorcaoComCusto> get porcoesAbaixoDaMeta =>
      porcoes.where((p) => p.margemAbaixoDaMeta).toList();

  bool get algumaPorcaoAbaixoDaMeta => porcoes.any((p) => p.margemAbaixoDaMeta);

  /// Total de insumos somando todas as porções (inclui os que vêm dentro de
  /// componentes).
  int get quantidadeItens =>
      porcoes.fold(0, (sum, p) => sum + p.quantidadeItens);
}
