/// Tendência de preço de um insumo com base nas últimas 3 compras.
enum TendenciaPreco {
  alta, // Preço subiu
  estavel, // Preço manteve-se próximo
  queda; // Preço caiu

  /// Calcula a tendência com base em uma lista de preços históricos (do mais
  /// antigo para o mais recente). Usa variação percentual entre o mais
  /// recente e o mais antigo da janela.
  static TendenciaPreco calcular(List<double> precos) {
    if (precos.length < 2) return TendenciaPreco.estavel;
    final janela = precos.length > 3
        ? precos.sublist(precos.length - 3)
        : precos;
    final primeiro = janela.first;
    final ultimo = janela.last;
    if (primeiro == 0.0) return TendenciaPreco.estavel;
    final variacao = (ultimo - primeiro) / primeiro;
    if (variacao > 0.02) return TendenciaPreco.alta;
    if (variacao < -0.02) return TendenciaPreco.queda;
    return TendenciaPreco.estavel;
  }
}
