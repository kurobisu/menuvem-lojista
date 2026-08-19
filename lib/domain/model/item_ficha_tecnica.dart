/// Um insumo solto na ficha técnica de uma [Porcao], com a quantidade usada.
///
/// "Solto" = lançado direto na porção, sem passar por um [Componente].
///
/// [quantidade]: quantidade do insumo na porção, na unidadeUso do insumo.
/// [perdaPercentual]: perda/rendimento do preparo (%). Ex.: 20 significa que
/// o insumo rende 80%, encarecendo a porção real. Padrão 0.
class ItemFichaTecnica {
  final int id;
  final int porcaoId;
  final int insumoId;
  final double quantidade;
  final double perdaPercentual;

  const ItemFichaTecnica({
    this.id = 0,
    required this.porcaoId,
    required this.insumoId,
    required this.quantidade,
    this.perdaPercentual = 0.0,
  });

  ItemFichaTecnica copyWith({
    int? id,
    int? porcaoId,
    int? insumoId,
    double? quantidade,
    double? perdaPercentual,
  }) {
    return ItemFichaTecnica(
      id: id ?? this.id,
      porcaoId: porcaoId ?? this.porcaoId,
      insumoId: insumoId ?? this.insumoId,
      quantidade: quantidade ?? this.quantidade,
      perdaPercentual: perdaPercentual ?? this.perdaPercentual,
    );
  }
}
