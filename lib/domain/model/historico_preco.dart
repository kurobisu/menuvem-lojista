/// Registro histórico de preço de um insumo.
///
/// [preco]: preço pago por unidade de COMPRA do insumo.
/// [listaComprasId]: lista de compras de origem deste registro.
class HistoricoPreco {
  final int id;
  final int insumoId;
  final double preco;
  final DateTime data;
  final int listaComprasId;
  final String listaComprasNome;

  HistoricoPreco({
    this.id = 0,
    required this.insumoId,
    required this.preco,
    DateTime? data,
    required this.listaComprasId,
    this.listaComprasNome = '',
  }) : data = data ?? DateTime.now();
}
