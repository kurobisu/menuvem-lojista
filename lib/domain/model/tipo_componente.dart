/// Tipo de um Componente (bloco reutilizável de ficha técnica), cadastrado
/// livremente pelo usuário — ex.: "Massa", "Sabor", "Embalagem" — para
/// organizar a biblioteca de componentes. Não é mais uma lista fixa: o
/// usuário digita o nome ao criar/editar um componente e o tipo é reutilizado
/// (por nome, sem diferenciar maiúsculas/minúsculas) nas próximas vezes.
class TipoComponente {
  final int id;
  final String nome;
  final DateTime dataCriacao;

  TipoComponente({
    this.id = 0,
    required this.nome,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();
}
