import 'package:flutter/material.dart';

import '../../domain/model/produto.dart';
import '../components/emoji_picker_field.dart';
import '../components/emojis.dart';
import '../components/form_sheet_header.dart';
import '../components/formatters.dart';

typedef ProdutoFormConfirm =
    void Function(
      String nome,
      String? emoji,
      double margemAlvo,
      double? precoVenda,
    );

/// Folha de criação/edição de produto.
///
/// Na **criação**, o formulário também pergunta margem-alvo e preço — eles
/// alimentam a porção inicial ("Única"), para que quem vende produto de
/// tamanho único nunca precise saber que porções existem. Na **edição**, só
/// nome e ícone aparecem: margem e preço passam a ser editados por porção.
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
  late final _nomeController = TextEditingController(
    text: widget.produto?.nome ?? '',
  );
  final _margemController = TextEditingController(text: '30');
  final _precoController = TextEditingController();
  late String? _emoji = widget.produto?.emoji;

  /// Margem e preço só entram na criação — na edição eles vivem na porção.
  bool get _isCriacao => widget.produto == null;

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
    final precoVal = parseMoedaPtBr(_precoController.text);
    final precificacaoValida =
        !_isCriacao ||
        (margemVal != null &&
            margemVal >= 0 &&
            margemVal <= 99.9 &&
            (_precoController.text.trim().isEmpty || precoVal != null));
    final isValid =
        _nomeController.text.trim().isNotEmpty && precificacaoValida;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSheetHeader(
              titulo: _isCriacao ? 'Novo Produto' : 'Editar Produto',
              onCancelar: () => Navigator.of(context).pop(),
              onSalvar: isValid
                  ? () {
                      widget.onConfirm(
                        _nomeController.text.trim(),
                        _emoji,
                        margemVal ?? 30.0,
                        _precoController.text.trim().isEmpty
                            ? null
                            : precoVal,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Pizza de Calabresa',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              'Ícone (opcional)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            EmojiPickerField(
              opcoes: emojisProduto,
              selecionado: _emoji,
              onChanged: (v) => setState(() => _emoji = v),
            ),
            if (_isCriacao) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _margemController,
                decoration: const InputDecoration(
                  labelText: 'Margem de lucro alvo (%)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _precoController,
                inputFormatters: const [MoedaInputFormatter()],
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  labelText: 'Preço de venda atual (opcional)',
                  hintText: '0,00',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Margem e preço são definidos em cada porção.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
