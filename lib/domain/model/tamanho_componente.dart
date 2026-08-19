/// Tamanho/variação de um [Componente] (ex.: "Único", "35cm", "Família").
///
/// Todo componente tem **pelo menos um** tamanho — componentes sem variação
/// ficam com um tamanho "Único", que a UI esconde, mesmo padrão de `Porcao`
/// para `Produto`. Serve para variar a quantidade de insumo entre tamanhos
/// (ex.: massa de 25cm x 35cm) sem duplicar o componente inteiro.
class TamanhoComponente {
  final int id;
  final int componenteId;
  final String nome;
  final int ordem;
  final DateTime dataCriacao;

  TamanhoComponente({
    this.id = 0,
    required this.componenteId,
    required this.nome,
    this.ordem = 0,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  TamanhoComponente copyWith({
    int? id,
    int? componenteId,
    String? nome,
    int? ordem,
    DateTime? dataCriacao,
  }) {
    return TamanhoComponente(
      id: id ?? this.id,
      componenteId: componenteId ?? this.componenteId,
      nome: nome ?? this.nome,
      ordem: ordem ?? this.ordem,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TamanhoComponente &&
      id == other.id &&
      componenteId == other.componenteId &&
      nome == other.nome &&
      ordem == other.ordem;

  @override
  int get hashCode => Object.hash(id, componenteId, nome, ordem);
}
