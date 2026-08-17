/// Item dentro de uma lista de compras.
///
/// [insumoId]: null se o item não estiver vinculado a um insumo cadastrado.
/// [nomeItem]: nome exibido (pode ser o nome do insumo ou digitado livremente).
/// [quantidade]: quantidade prevista na lista.
/// [unidade]: unidade de medida do item nesta lista.
/// [precoUnitario]: preço por unidade registrado na compra (preenchido ao marcar).
/// [comprado]: true quando o usuário marcou como comprado.
class ItemLista {
  final int id;
  final int listaComprasId;
  final int? insumoId;
  final String nomeItem;
  final double quantidade;
  final String unidade;
  final double precoUnitario;
  final bool comprado;

  const ItemLista({
    this.id = 0,
    required this.listaComprasId,
    this.insumoId,
    required this.nomeItem,
    required this.quantidade,
    required this.unidade,
    this.precoUnitario = 0.0,
    this.comprado = false,
  });

  double get precoTotal => quantidade * precoUnitario;

  bool get estaVinculado => insumoId != null;

  ItemLista copyWith({
    int? id,
    int? listaComprasId,
    int? insumoId,
    String? nomeItem,
    double? quantidade,
    String? unidade,
    double? precoUnitario,
    bool? comprado,
  }) {
    return ItemLista(
      id: id ?? this.id,
      listaComprasId: listaComprasId ?? this.listaComprasId,
      insumoId: insumoId ?? this.insumoId,
      nomeItem: nomeItem ?? this.nomeItem,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      comprado: comprado ?? this.comprado,
    );
  }
}
