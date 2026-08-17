import 'package:flutter/material.dart';

import '../../domain/model/categoria_insumo.dart';
import '../../domain/model/insumo.dart';
import '../components/formatters.dart';

typedef InsumoFormConfirm = void Function({
  required String nome,
  required CategoriaInsumo categoria,
  required String unidadeCompra,
  required String unidadeUso,
  required double fatorConversao,
  required double custoAtual,
});

/// Dialog de criação/edição de insumo da biblioteca: nome, categoria
/// (insumo/embalagem), unidade de compra, unidade de uso, fator de conversão
/// e custo atual (override manual do preço vindo do histórico de compras).
class InsumoFormDialog extends StatefulWidget {
  const InsumoFormDialog({
    super.key,
    this.insumo,
    required this.onConfirm,
  });

  final Insumo? insumo;
  final InsumoFormConfirm onConfirm;

  @override
  State<InsumoFormDialog> createState() => _InsumoFormDialogState();
}

class _InsumoFormDialogState extends State<InsumoFormDialog> {
  late final _nomeController = TextEditingController(text: widget.insumo?.nome ?? '');
  late CategoriaInsumo _categoria = widget.insumo?.categoria ?? CategoriaInsumo.insumo;
  late final _unidadeCompraController =
      TextEditingController(text: widget.insumo?.unidadeCompra ?? '');
  late final _unidadeUsoController =
      TextEditingController(text: widget.insumo?.unidadeUso ?? '');
  late final _fatorController = TextEditingController(
    text: widget.insumo == null
        ? ''
        : (widget.insumo!.fatorConversao % 1.0 == 0.0
            ? widget.insumo!.fatorConversao.toInt().toString()
            : widget.insumo!.fatorConversao.toString().replaceAll('.', ',')),
  );
  late final _custoController = TextEditingController(
    text: (widget.insumo?.custoAtual ?? 0) > 0
        ? formatarMoeda(widget.insumo!.custoAtual)
        : '',
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _unidadeCompraController.dispose();
    _unidadeUsoController.dispose();
    _fatorController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fatorVal = parseDecimalPtBr(_fatorController.text);
    final custoVal = parseDecimalPtBr(_custoController.text);
    final isValid = _nomeController.text.trim().isNotEmpty &&
        _unidadeCompraController.text.trim().isNotEmpty &&
        _unidadeUsoController.text.trim().isNotEmpty &&
        fatorVal != null &&
        fatorVal > 0 &&
        (_custoController.text.trim().isEmpty || custoVal != null);

    return AlertDialog(
      title: Text(widget.insumo == null ? 'Novo Insumo' : 'Editar Insumo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Calabresa',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Insumo'),
                  selected: _categoria == CategoriaInsumo.insumo,
                  onSelected: (_) =>
                      setState(() => _categoria = CategoriaInsumo.insumo),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Embalagem'),
                  selected: _categoria == CategoriaInsumo.embalagem,
                  onSelected: (_) =>
                      setState(() => _categoria = CategoriaInsumo.embalagem),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unidadeCompraController,
                    decoration: const InputDecoration(
                      labelText: 'Un. compra',
                      hintText: 'kg',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unidadeUsoController,
                    decoration: const InputDecoration(
                      labelText: 'Un. uso',
                      hintText: 'g',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatorController,
              decoration: const InputDecoration(
                labelText: 'Fator de conversão',
                hintText: 'Ex.: 1000 (1 kg = 1000 g)',
                helperText: 'Quantas unidades de uso cabem em 1 unidade de compra',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _custoController,
              decoration: const InputDecoration(
                labelText: 'Custo por un. de compra (opcional)',
                hintText: 'Ex.: 46,18',
                helperText: 'Atualizado automaticamente pelas compras finalizadas',
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
                    nome: _nomeController.text.trim(),
                    categoria: _categoria,
                    unidadeCompra: _unidadeCompraController.text.trim(),
                    unidadeUso: _unidadeUsoController.text.trim(),
                    fatorConversao: fatorVal,
                    custoAtual: custoVal ?? 0.0,
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
