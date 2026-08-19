import 'categoria_insumo.dart';

/// Insumo (ingrediente/matéria-prima).
///
/// [unidadeCompra] ex: "kg", "cx", "fardo". [unidadeUso] ex: "g", "un".
/// [fatorConversao]: quantas unidades de uso existem em 1 unidade de compra
/// (ex.: 1 kg = 1000 g → fatorConversao = 1000.0).
/// [custoAtual]: preço da última compra, por unidade de COMPRA.
class Insumo {
  final int id;
  final String nome;
  final String unidadeCompra;
  final String unidadeUso;
  final double fatorConversao;
  final double custoAtual;
  final DateTime dataCriacao;
  final CategoriaInsumo categoria;
  final String? emoji;

  Insumo({
    this.id = 0,
    required this.nome,
    required this.unidadeCompra,
    required this.unidadeUso,
    required this.fatorConversao,
    this.custoAtual = 0.0,
    DateTime? dataCriacao,
    this.categoria = CategoriaInsumo.insumo,
    this.emoji,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  /// Custo por unidade de uso (calculado).
  double get custoPorUnidadeUso =>
      fatorConversao > 0 ? custoAtual / fatorConversao : 0.0;

  Insumo copyWith({
    int? id,
    String? nome,
    String? unidadeCompra,
    String? unidadeUso,
    double? fatorConversao,
    double? custoAtual,
    DateTime? dataCriacao,
    CategoriaInsumo? categoria,
    String? emoji,
    bool clearEmoji = false,
  }) {
    return Insumo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      unidadeCompra: unidadeCompra ?? this.unidadeCompra,
      unidadeUso: unidadeUso ?? this.unidadeUso,
      fatorConversao: fatorConversao ?? this.fatorConversao,
      custoAtual: custoAtual ?? this.custoAtual,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      categoria: categoria ?? this.categoria,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Insumo &&
      id == other.id &&
      nome == other.nome &&
      unidadeCompra == other.unidadeCompra &&
      unidadeUso == other.unidadeUso &&
      fatorConversao == other.fatorConversao &&
      custoAtual == other.custoAtual &&
      categoria == other.categoria &&
      emoji == other.emoji;

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    unidadeCompra,
    unidadeUso,
    fatorConversao,
    custoAtual,
    categoria,
    emoji,
  );
}
