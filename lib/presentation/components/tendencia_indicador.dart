import 'package:flutter/material.dart';

import '../../domain/model/tendencia_preco.dart';
import '../../theme/app_theme.dart';

/// Indicador visual de tendência de preço (↑ Alta / → Estável / ↓ Queda).
class TendenciaIndicador extends StatelessWidget {
  const TendenciaIndicador({
    super.key,
    required this.tendencia,
    this.showLabel = false,
  });

  final TendenciaPreco tendencia;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final (Color cor, IconData icone, String label) = switch (tendencia) {
      TendenciaPreco.alta => (trendUp, Icons.trending_up, 'Alta'),
      TendenciaPreco.estavel => (trendStable, Icons.trending_flat, 'Estável'),
      TendenciaPreco.queda => (trendDown, Icons.trending_down, 'Queda'),
    };

    return Container(
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cor),
            ),
          ],
        ],
      ),
    );
  }
}
