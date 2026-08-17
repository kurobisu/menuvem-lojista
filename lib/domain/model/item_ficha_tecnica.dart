/// Um insumo que compõe um Produto, com a quantidade usada por porção.
///
/// [quantidade]: quantidade do insumo por porção, na unidadeUso do insumo.
/// [perdaPercentual]: perda/rendimento do preparo (%). Ex.: 20 significa que
/// o insumo rende 80%, encarecendo a porção real. Padrão 0.
class ItemFichaTecnica {
  final int id;
  final int produtoId;
  final int insumoId;
  final double quantidade;
  final double perdaPercentual;

  const ItemFichaTecnica({
    this.id = 0,
    required this.produtoId,
    required this.insumoId,
    required this.quantidade,
    this.perdaPercentual = 0.0,
  });

  ItemFichaTecnica copyWith({
    int? id,
    int? produtoId,
    int? insumoId,
    double? quantidade,
    double? perdaPercentual,
  }) {
    return ItemFichaTecnica(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      insumoId: insumoId ?? this.insumoId,
      quantidade: quantidade ?? this.quantidade,
      perdaPercentual: perdaPercentual ?? this.perdaPercentual,
    );
  }
}
