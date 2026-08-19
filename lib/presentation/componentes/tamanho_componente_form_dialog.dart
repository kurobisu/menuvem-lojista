import 'package:flutter/material.dart';

import '../../domain/model/tamanho_componente.dart';
import '../components/form_sheet_header.dart';

typedef TamanhoComponenteFormConfirm =
    void Function({required String nome, int? copiarItensDoTamanhoId});

/// Folha de criação/edição de um tamanho de componente.
///
/// Na criação, quando o componente já tem outros tamanhos, oferece copiar os
/// itens de um deles — é o caminho normal de "Único" → "35cm", onde muda só
/// a quantidade dos mesmos insumos.
class TamanhoComponenteFormDialog extends StatefulWidget {
  const TamanhoComponenteFormDialog({
    super.key,
    this.tamanho,
    this.tamanhosParaCopiar = const [],
    required this.onConfirm,
  });

  /// Null = criação.
  final TamanhoComponente? tamanho;

  /// Tamanhos existentes cujos itens podem ser copiados (vazio na criação do
  /// primeiro tamanho, ou sempre vazio na edição).
  final List<TamanhoComponente> tamanhosParaCopiar;

  final TamanhoComponenteFormConfirm onConfirm;

  @override
  State<TamanhoComponenteFormDialog> createState() =>
      _TamanhoComponenteFormDialogState();
}

class _TamanhoComponenteFormDialogState
    extends State<TamanhoComponenteFormDialog> {
  late final _nomeController = TextEditingController(
    text: widget.tamanho?.nome ?? '',
  );

  /// Tamanho cujos itens serão copiados; null = começar vazio.
  int? _copiarDe;

  bool get _isCriacao => widget.tamanho == null;

  @override
  void initState() {
    super.initState();
    if (_isCriacao && widget.tamanhosParaCopiar.isNotEmpty) {
      _copiarDe = widget.tamanhosParaCopiar.first.id;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nomeController.text.trim().isNotEmpty;

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
              titulo: _isCriacao ? 'Novo Tamanho' : 'Editar Tamanho',
              onCancelar: () => Navigator.of(context).pop(),
              onSalvar: isValid
                  ? () {
                      widget.onConfirm(
                        nome: _nomeController.text.trim(),
                        copiarItensDoTamanhoId: _isCriacao ? _copiarDe : null,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do tamanho',
                hintText: 'Ex.: 35cm, Família',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            if (_isCriacao && widget.tamanhosParaCopiar.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Insumos',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Copie de outro tamanho e ajuste só as quantidades.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<int?>(
                groupValue: _copiarDe,
                onChanged: (v) => setState(() => _copiarDe = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in widget.tamanhosParaCopiar)
                      RadioListTile<int?>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: t.id,
                        title: Text('Copiar de "${t.nome}"'),
                      ),
                    const RadioListTile<int?>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: null,
                      title: Text('Começar vazio'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
