/// Produto (item vendido pela loja, ex.: Pizza Grande de Calabresa).
/// O custo é calculado a partir da ficha técnica (ver [ItemFichaTecnica]).
///
/// [margemAlvoPercentual]: margem de lucro desejada sobre o preço de venda (%).
/// Preço sugerido = custo / (1 - margem/100).
/// [precoVendaAtual]: preço praticado hoje (opcional) — usado para comparar a
/// margem real com a margem-alvo.
class Produto {
  final int id;
  final String nome;
  final double margemAlvoPercentual;
  final double? precoVendaAtual;
  final String? emoji;
  final DateTime dataCriacao;

  Produto({
    this.id = 0,
    required this.nome,
    this.margemAlvoPercentual = 30.0,
    this.precoVendaAtual,
    this.emoji,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Produto copyWith({
    int? id,
    String? nome,
    double? margemAlvoPercentual,
    double? precoVendaAtual,
    bool clearPrecoVendaAtual = false,
    String? emoji,
    bool clearEmoji = false,
    DateTime? dataCriacao,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      margemAlvoPercentual: margemAlvoPercentual ?? this.margemAlvoPercentual,
      precoVendaAtual: clearPrecoVendaAtual
          ? null
          : (precoVendaAtual ?? this.precoVendaAtual),
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Produto &&
      id == other.id &&
      nome == other.nome &&
      margemAlvoPercentual == other.margemAlvoPercentual &&
      precoVendaAtual == other.precoVendaAtual &&
      emoji == other.emoji;

  @override
  int get hashCode =>
      Object.hash(id, nome, margemAlvoPercentual, precoVendaAtual, emoji);
}
