import 'componente.dart';
import 'item_componente_com_insumo.dart';

/// Componente enriquecido com seus itens (com insumo) e o custo por inteiro
/// (multiplicador 1). Usado na biblioteca de componentes e na busca ao
/// montar um produto.
class ComponenteComCusto {
  final Componente componente;
  final List<ItemComponenteComInsumo> itens;

  const ComponenteComCusto({required this.componente, required this.itens});

  double get custo => itens.fold(0.0, (sum, item) => sum + item.custo);

  int get quantidadeItens => itens.length;
}
