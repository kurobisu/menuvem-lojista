import '../../domain/model/tipo_componente.dart';

/// Rótulo pt-BR de um tipo de componente.
String formatarTipo(TipoComponente tipo) {
  switch (tipo) {
    case TipoComponente.massa:
      return 'Massa';
    case TipoComponente.sabor:
      return 'Sabor';
    case TipoComponente.embalagem:
      return 'Embalagem';
    case TipoComponente.outro:
      return 'Outro';
  }
}

/// Converte um multiplicador no divisor (n) correspondente para edição.
String divisorDeMultiplicador(double multiplicador) {
  if (multiplicador <= 0) return '1';
  final inverso = 1.0 / multiplicador;
  final n = inverso.round();
  return (inverso - n).abs() < 0.001 ? n.toString() : inverso.toStringAsFixed(2);
}

/// Converte o divisor (n) no multiplicador 1/n.
double multiplicadorDeDivisor(int divisor) => divisor > 0 ? 1.0 / divisor : 1.0;

/// Descreve o multiplicador para exibição (ex.: "× 1/2 · 2 partes").
String descreverMultiplicador(double multiplicador) {
  if (multiplicador == 1.0) return '× 1 · inteiro';
  final inverso = 1.0 / multiplicador;
  final n = inverso.round();
  if (n > 1 && (inverso - n).abs() < 0.001) {
    return '× 1/$n · $n partes';
  }
  return '× ${multiplicador.toStringAsFixed(2)}';
}
