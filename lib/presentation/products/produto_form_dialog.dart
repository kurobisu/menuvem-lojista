import 'package:flutter/material.dart';

import '../../domain/model/produto.dart';
import '../components/formatters.dart';

typedef ProdutoFormConfirm = void Function(
  String nome,
  double margemAlvo,
  double? precoVenda,
);

/// Dialog de criação/edição de produto: nome, margem-alvo (%) e preço de
/// venda atual (opcional — usado para comparar a margem real com a meta).
class ProdutoFormDialog extends StatefulWidget {
  const ProdutoFormDialog({super.key, this.produto, required this.onConfirm});

  final Produto? produto;
  final ProdutoFormConfirm onConfirm;

  @override
  State<ProdutoFormDialog> createState() => _ProdutoFormDialogState();
}

class _ProdutoFormDialogState extends State<ProdutoFormDialog> {
  late final _nomeController = TextEditingController(text: widget.produto?.nome ?? '');
  late final _margemController = TextEditingController(
    text: widget.produto == null
        ? '30'
        : (widget.produto!.margemAlvoPercentual % 1.0 == 0.0
            ? widget.produto!.margemAlvoPercentual.toInt().toString()
            : widget.produto!.margemAlvoPercentual.toString().replaceAll('.', ',')),
  );
  late final _precoController = TextEditingController(
    text: widget.produto?.precoVendaAtual != null
        ? formatarMoeda(widget.produto!.precoVendaAtual!)
        : '',
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _margemController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final margemVal = parseDecimalPtBr(_margemController.text);
    final precoVal = parseDecimalPtBr(_precoController.text);
    final isValid = _nomeController.text.trim().isNotEmpty &&
        margemVal != null &&
        margemVal >= 0 &&
        margemVal <= 99.9 &&
        (_precoController.text.trim().isEmpty || precoVal != null);

    return AlertDialog(
      title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Pizza Grande de Calabresa',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _margemController,
              decoration: const InputDecoration(labelText: 'Margem de lucro alvo (%)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precoController,
              decoration: const InputDecoration(
                labelText: 'Preço de venda atual (opcional)',
                hintText: '0,00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: isValid
              ? () {
                  widget.onConfirm(
                    _nomeController.text.trim(),
                    margemVal,
                    _precoController.text.trim().isEmpty ? null : precoVal,
                  );
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
