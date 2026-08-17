/// Vínculo de um Componente a um Produto, com o multiplicador aplicado.
///
/// [multiplicador]: fração do componente usada no produto. Ex.: sabor único
/// numa pizza = 1.0 (inteiro); 2 sabores = 0.5 (metade); 3 sabores = 1/3.
/// Massa/base e embalagem normalmente usam 1.0.
class ProdutoComponente {
  final int id;
  final int produtoId;
  final int componenteId;
  final double multiplicador;

  const ProdutoComponente({
    this.id = 0,
    required this.produtoId,
    required this.componenteId,
    this.multiplicador = 1.0,
  });

  ProdutoComponente copyWith({
    int? id,
    int? produtoId,
    int? componenteId,
    double? multiplicador,
  }) {
    return ProdutoComponente(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      componenteId: componenteId ?? this.componenteId,
      multiplicador: multiplicador ?? this.multiplicador,
    );
  }
}
