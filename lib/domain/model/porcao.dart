/// Porção de um [Produto]: um tamanho/variação vendável (P, M, G, Família…),
/// com ficha técnica, margem-alvo e preço próprios.
///
/// Todo produto tem **pelo menos uma** porção — produtos de tamanho único
/// ficam com uma porção "Única", que a UI esconde para não expor a
/// complexidade de porções a quem não precisa dela.
///
/// [ordem]: posição de exibição entre as porções do produto.
/// [margemAlvoPercentual]: margem de lucro desejada sobre o preço de venda
/// (%) — preço sugerido = custo / (1 − margem/100).
/// [precoVendaAtual]: preço praticado hoje nesta porção (opcional), usado
/// para comparar a margem real com a margem-alvo.
class Porcao {
  final int id;
  final int produtoId;
  final String nome;
  final int ordem;
  final double margemAlvoPercentual;
  final double? precoVendaAtual;
  final DateTime dataCriacao;

  Porcao({
    this.id = 0,
    required this.produtoId,
    required this.nome,
    this.ordem = 0,
    this.margemAlvoPercentual = 30.0,
    this.precoVendaAtual,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Porcao copyWith({
    int? id,
    int? produtoId,
    String? nome,
    int? ordem,
    double? margemAlvoPercentual,
    double? precoVendaAtual,
    bool clearPrecoVendaAtual = false,
    DateTime? dataCriacao,
  }) {
    return Porcao(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      nome: nome ?? this.nome,
      ordem: ordem ?? this.ordem,
      margemAlvoPercentual: margemAlvoPercentual ?? this.margemAlvoPercentual,
      precoVendaAtual: clearPrecoVendaAtual
          ? null
          : (precoVendaAtual ?? this.precoVendaAtual),
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Porcao &&
      id == other.id &&
      produtoId == other.produtoId &&
      nome == other.nome &&
      ordem == other.ordem &&
      margemAlvoPercentual == other.margemAlvoPercentual &&
      precoVendaAtual == other.precoVendaAtual;

  @override
  int get hashCode => Object.hash(
    id,
    produtoId,
    nome,
    ordem,
    margemAlvoPercentual,
    precoVendaAtual,
  );
}
