import 'package:flutter/material.dart';

import 'formatters.dart';

/// Diálogo genérico de edição de quantidade + perda de um item de ficha
/// (usado tanto na ficha de produto quanto nos itens de um componente).
class EditarQuantidadeDialog extends StatefulWidget {
  const EditarQuantidadeDialog({
    super.key,
    required this.titulo,
    required this.unidadeUso,
    required this.quantidadeInicial,
    required this.perdaInicial,
    required this.onConfirm,
  });

  final String titulo;
  final String unidadeUso;
  final double quantidadeInicial;
  final double perdaInicial;
  final void Function(double quantidade, double perda) onConfirm;

  @override
  State<EditarQuantidadeDialog> createState() => _EditarQuantidadeDialogState();
}

class _EditarQuantidadeDialogState extends State<EditarQuantidadeDialog> {
  late final _quantidadeController = TextEditingController(
    text: widget.quantidadeInicial % 1.0 == 0.0
        ? widget.quantidadeInicial.toInt().toString()
        : widget.quantidadeInicial.toStringAsFixed(2),
  );
  late final _perdaController = TextEditingController(
    text: widget.perdaInicial % 1.0 == 0.0
        ? widget.perdaInicial.toInt().toString()
        : widget.perdaInicial.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _quantidadeController.dispose();
    _perdaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantidadeVal = parseDecimalPtBr(_quantidadeController.text);
    final perdaVal = parseDecimalPtBr(_perdaController.text);
    final isValid = quantidadeVal != null &&
        quantidadeVal > 0 &&
        perdaVal != null &&
        perdaVal >= 0 &&
        perdaVal <= 99.9;

    return AlertDialog(
      title: Text(widget.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantidadeController,
            decoration: InputDecoration(labelText: 'Quantidade (${widget.unidadeUso})'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _perdaController,
            decoration: const InputDecoration(labelText: 'Perda (%)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: isValid
              ? () {
                  widget.onConfirm(quantidadeVal, perdaVal);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
