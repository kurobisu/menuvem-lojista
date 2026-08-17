/// Status de uma lista de compras.
enum StatusLista { aberta, finalizada }

/// Lista de Compras.
class ListaCompras {
  final int id;
  final String nome;
  final DateTime dataCriacao;
  final DateTime? dataFinalizacao;
  final double totalGasto;
  final StatusLista status;

  ListaCompras({
    this.id = 0,
    required this.nome,
    DateTime? dataCriacao,
    this.dataFinalizacao,
    this.totalGasto = 0.0,
    this.status = StatusLista.aberta,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  ListaCompras copyWith({
    int? id,
    String? nome,
    DateTime? dataCriacao,
    DateTime? dataFinalizacao,
    double? totalGasto,
    StatusLista? status,
  }) {
    return ListaCompras(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataFinalizacao: dataFinalizacao ?? this.dataFinalizacao,
      totalGasto: totalGasto ?? this.totalGasto,
      status: status ?? this.status,
    );
  }
}
