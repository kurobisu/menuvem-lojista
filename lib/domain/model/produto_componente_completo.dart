import 'componente.dart';
import 'item_componente_com_insumo.dart';
import 'produto_componente.dart';

/// Componente aplicado a um produto, enriquecido com os dados do componente
/// e seus itens (com insumo) para exibição e cálculo de custo no produto.
///
/// [custo]: custo da parcela deste componente no produto = soma dos itens
/// (por inteiro) × multiplicador do vínculo.
class ProdutoComponenteCompleto {
  final ProdutoComponente vinculo;
  final Componente componente;
  final List<ItemComponenteComInsumo> itens;

  const ProdutoComponenteCompleto({
    required this.vinculo,
    required this.componente,
    required this.itens,
  });

  double get custo =>
      itens.fold(0.0, (sum, item) => sum + item.custo) * vinculo.multiplicador;

  int get quantidadeItens => itens.length;
}
