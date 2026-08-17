import 'insumo.dart';
import 'item_componente.dart';

/// Item de componente enriquecido com o insumo correspondente, usado no
/// cálculo de custo (quantidade × custoPorUnidadeUso, com perda).
class ItemComponenteComInsumo {
  final ItemComponente item;
  final Insumo insumo;

  const ItemComponenteComInsumo({required this.item, required this.insumo});

  /// Custo do item por inteiro (multiplicador 1), considerando perda.
  double get custo {
    final perda = item.perdaPercentual.clamp(0.0, 99.9);
    return item.quantidade * insumo.custoPorUnidadeUso / (1.0 - perda / 100.0);
  }
}
