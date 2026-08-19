/// Produto (item vendido pela loja, ex.: Pizza de Calabresa).
///
/// O produto é só a "família": nome e ícone. Custo, margem-alvo e preço
/// vivem em cada [Porcao] — um produto tem uma porção "Única" quando é de
/// tamanho único, ou várias (P, M, G, Família…) quando é vendido em
/// tamanhos diferentes com a mesma receita base.
class Produto {
  final int id;
  final String nome;
  final String? emoji;
  final DateTime dataCriacao;

  Produto({this.id = 0, required this.nome, this.emoji, DateTime? dataCriacao})
    : dataCriacao = dataCriacao ?? DateTime.now();

  Produto copyWith({
    int? id,
    String? nome,
    String? emoji,
    bool clearEmoji = false,
    DateTime? dataCriacao,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Produto &&
      id == other.id &&
      nome == other.nome &&
      emoji == other.emoji;

  @override
  int get hashCode => Object.hash(id, nome, emoji);
}
