import 'insumo.dart';
import 'item_ficha_tecnica.dart';

/// Item da ficha técnica enriquecido com o insumo correspondente, usado no
/// cálculo de custo do produto.
class ItemFichaComInsumo {
  final ItemFichaTecnica item;
  final Insumo insumo;

  const ItemFichaComInsumo({required this.item, required this.insumo});

  /// Custo do item por porção, considerando a perda/rendimento:
  /// quantidade × custoPorUnidadeUso ÷ (1 − perda/100).
  /// Ex.: 1 kg de tomate com 20% de perda rende 800 g — usar 800 g custa o
  /// preço de 1000 g.
  double get custo {
    final perda = item.perdaPercentual.clamp(0.0, 99.9);
    return item.quantidade * insumo.custoPorUnidadeUso / (1.0 - perda / 100.0);
  }
}
