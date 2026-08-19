import 'componente.dart';
import 'tamanho_componente_com_custo.dart';

/// Componente enriquecido com seus tamanhos custeados. Um componente sempre
/// tem pelo menos um tamanho ("Único"); com só esse, a UI trata o componente
/// como se não tivesse tamanhos. Usado na biblioteca de componentes e na
/// busca ao montar um produto.
class ComponenteComCusto {
  final Componente componente;
  final List<TamanhoComponenteComCusto> tamanhos;
  final String? tipoNome;

  const ComponenteComCusto({
    required this.componente,
    required this.tamanhos,
    this.tipoNome,
  });

  bool get temMultiplosTamanhos => tamanhos.length > 1;

  /// Tamanho usado para representar o componente em listagens compactas.
  /// Null só no caso degenerado de um componente sem nenhum tamanho (dado
  /// inconsistente — a UI trata mostrando o componente sem custo).
  TamanhoComponenteComCusto? get tamanhoPrincipal =>
      tamanhos.isEmpty ? null : tamanhos.first;

  double get custoMinimo => tamanhos.isEmpty
      ? 0.0
      : tamanhos.map((t) => t.custoTotal).reduce((a, b) => a < b ? a : b);

  double get custoMaximo => tamanhos.isEmpty
      ? 0.0
      : tamanhos.map((t) => t.custoTotal).reduce((a, b) => a > b ? a : b);

  /// Custo do tamanho principal — conveniência para telas que ainda não
  /// mostram a variação entre tamanhos (ex.: card da biblioteca).
  double get custo => tamanhoPrincipal?.custoTotal ?? 0.0;

  /// Total de insumos somando todos os tamanhos.
  int get quantidadeItens =>
      tamanhos.fold(0, (sum, t) => sum + t.quantidadeItens);
}
