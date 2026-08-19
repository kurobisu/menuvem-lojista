/// Componente: bloco reutilizável de ficha técnica.
///
/// Um componente é um "template" de itens (insumos + quantidades) que pode
/// ser reaproveitado em vários produtos — ex.: "Pizza - Massa Grande 35cm"
/// (base de massa) e "Pizza Sabor - Calabresa" (recheio). Ao montar um
/// produto, o componente entra com um multiplicador (ver
/// [ProdutoComponente]) — ex.: sabor único = 1; 2 sabores na mesma massa =
/// 0,5; 3 sabores = 1/3.
///
/// [tipoComponenteId]: tipo cadastrado livremente pelo usuário (ver
/// [TipoComponente]), opcional — organiza a biblioteca e os filtros.
/// [ordem]: posição de exibição na biblioteca, ajustável arrastando na tela
/// de Componentes (só disponível com o filtro "Todos" ativo).
class Componente {
  final int id;
  final String nome;
  final int? tipoComponenteId;
  final int ordem;
  final String? emoji;
  final DateTime dataCriacao;

  Componente({
    this.id = 0,
    required this.nome,
    this.tipoComponenteId,
    this.ordem = 0,
    this.emoji,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Componente copyWith({
    int? id,
    String? nome,
    int? tipoComponenteId,
    bool clearTipoComponenteId = false,
    int? ordem,
    String? emoji,
    bool clearEmoji = false,
  }) {
    return Componente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipoComponenteId: clearTipoComponenteId
          ? null
          : (tipoComponenteId ?? this.tipoComponenteId),
      ordem: ordem ?? this.ordem,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      dataCriacao: dataCriacao,
    );
  }
}
