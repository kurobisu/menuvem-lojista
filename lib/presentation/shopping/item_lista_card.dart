import 'package:flutter/material.dart';

import '../../domain/model/item_lista.dart';
import '../../domain/model/tendencia_preco.dart';
import '../components/formatters.dart';
import '../components/tendencia_indicador.dart';

/// Card de item na lista de compras: checkbox, nome, quantidade/unidade,
/// preço editável (subtotal quando comprado), tendência e exclusão.
class ItemListaCard extends StatefulWidget {
  const ItemListaCard({
    super.key,
    required this.item,
    required this.tendencia,
    required this.onToggle,
    required this.onDelete,
  });

  final ItemLista item;
  final TendenciaPreco? tendencia;
  final void Function(bool comprado, double preco) onToggle;
  final VoidCallback onDelete;

  @override
  State<ItemListaCard> createState() => _ItemListaCardState();
}

class _ItemListaCardState extends State<ItemListaCard> {
  late final _precoController = TextEditingController(
    text: widget.item.precoUnitario > 0 ? widget.item.precoUnitario.toString() : '',
  );

  @override
  void dispose() {
    _precoController.dispose();
    super.dispose();
  }

  static String _formatarNumero(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: item.comprado ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6) : null,
      elevation: item.comprado ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: item.comprado,
              onChanged: (checked) {
                final preco = parseDecimalPtBr(_precoController.text) ?? 0.0;
                widget.onToggle(checked ?? false, preco);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.nomeItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                decoration: item.comprado
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.comprado
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                              ),
                        ),
                      ),
                      if (item.estaVinculado) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_cart,
                            size: 10,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                      if (widget.tendencia != null) ...[
                        const SizedBox(width: 6),
                        TendenciaIndicador(tendencia: widget.tendencia!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatarNumero(item.quantidade)} ${item.unidade}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!item.comprado)
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _precoController,
                  decoration: const InputDecoration(labelText: 'R\$', isDense: true),
                  style: Theme.of(context).textTheme.bodySmall,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                )
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${formatarMoeda(item.precoUnitario)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '= R\$ ${formatarMoeda(item.precoTotal)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: Icon(
                Icons.delete,
                size: 18,
                color: colorScheme.error.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover item?'),
        content: Text('"${widget.item.nomeItem}" será removido da lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: Text('Remover', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
