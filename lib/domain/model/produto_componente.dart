/// Vínculo de um Componente a uma [Porcao], com o multiplicador aplicado.
///
/// [componenteId]: qual componente (independente do tamanho).
/// [tamanhoComponenteId]: qual tamanho **desse** componente foi aplicado —
/// todo componente tem ao menos um tamanho ("Único"), então este campo
/// nunca fica em aberto.
/// [multiplicador]: fração do componente usada na porção. Ex.: sabor único
/// numa pizza = 1.0 (inteiro); 2 sabores = 0.5 (metade); 3 sabores = 1/3.
/// Massa/base e embalagem normalmente usam 1.0.
class ProdutoComponente {
  final int id;
  final int porcaoId;
  final int componenteId;
  final int tamanhoComponenteId;
  final double multiplicador;

  const ProdutoComponente({
    this.id = 0,
    required this.porcaoId,
    required this.componenteId,
    required this.tamanhoComponenteId,
    this.multiplicador = 1.0,
  });

  ProdutoComponente copyWith({
    int? id,
    int? porcaoId,
    int? componenteId,
    int? tamanhoComponenteId,
    double? multiplicador,
  }) {
    return ProdutoComponente(
      id: id ?? this.id,
      porcaoId: porcaoId ?? this.porcaoId,
      componenteId: componenteId ?? this.componenteId,
      tamanhoComponenteId: tamanhoComponenteId ?? this.tamanhoComponenteId,
      multiplicador: multiplicador ?? this.multiplicador,
    );
  }
}
