import 'package:flutter/material.dart';

import '../../domain/model/produto.dart';
import '../../theme/app_theme.dart';
import '../components/emoji_picker_field.dart';
import '../components/emojis.dart';
import '../components/formatters.dart';

typedef ProdutoFormConfirm = void Function(
  String nome,
  double margemAlvo,
  double? precoVenda,
  String? emoji,
);

/// Folha de criação/edição de produto: nome, margem-alvo (%) e preço de
/// venda atual (opcional — usado para comparar a margem real com a meta).
///
/// O botão Salvar fica no cabeçalho fixo (nunca atrás do teclado) — só o
/// conteúdo abaixo rola.
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
  late String? _emoji = widget.produto?.emoji;

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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: isValid
                      ? () {
                          widget.onConfirm(
                            _nomeController.text.trim(),
                            margemVal,
                            _precoController.text.trim().isEmpty ? null : precoVal,
                            _emoji,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Salvar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            Text('Ícone (opcional)', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            EmojiPickerField(
              opcoes: emojisProduto,
              selecionado: _emoji,
              onChanged: (v) => setState(() => _emoji = v),
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
    );
  }
}
