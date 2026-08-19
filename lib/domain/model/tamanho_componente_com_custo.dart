import 'tamanho_componente.dart';

/// Tamanho de um componente com o custo calculado pelos seus itens (insumos
/// por inteiro). O custo vem pronto do cost_engine.
class TamanhoComponenteComCusto {
  final TamanhoComponente tamanho;
  final double custoTotal;
  final int quantidadeItens;

  const TamanhoComponenteComCusto({
    required this.tamanho,
    required this.custoTotal,
    required this.quantidadeItens,
  });
}
