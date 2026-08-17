/// Item de um Componente: um insumo com a quantidade usada quando o
/// componente é aplicado por inteiro (multiplicador 1).
///
/// [quantidade]: quantidade do insumo, na unidadeUso do insumo.
/// [perdaPercentual]: perda/rendimento do preparo (%). Padrão 0.
class ItemComponente {
  final int id;
  final int componenteId;
  final int insumoId;
  final double quantidade;
  final double perdaPercentual;

  const ItemComponente({
    this.id = 0,
    required this.componenteId,
    required this.insumoId,
    required this.quantidade,
    this.perdaPercentual = 0.0,
  });

  ItemComponente copyWith({
    int? id,
    int? componenteId,
    int? insumoId,
    double? quantidade,
    double? perdaPercentual,
  }) {
    return ItemComponente(
      id: id ?? this.id,
      componenteId: componenteId ?? this.componenteId,
      insumoId: insumoId ?? this.insumoId,
      quantidade: quantidade ?? this.quantidade,
      perdaPercentual: perdaPercentual ?? this.perdaPercentual,
    );
  }
}
