import 'package:flutter/material.dart';

import '../../domain/model/componente.dart';
import '../../domain/model/tipo_componente.dart';
import '../components/multiplicador_utils.dart';

typedef ComponenteFormConfirm = void Function(String nome, TipoComponente tipo);

/// Dialog de criação/edição de componente: nome + tipo (Massa, Sabor,
/// Embalagem, Outro). O tipo organiza a biblioteca e sugere divisões.
class ComponenteFormDialog extends StatefulWidget {
  const ComponenteFormDialog({super.key, this.componente, required this.onConfirm});

  final Componente? componente;
  final ComponenteFormConfirm onConfirm;

  @override
  State<ComponenteFormDialog> createState() => _ComponenteFormDialogState();
}

class _ComponenteFormDialogState extends State<ComponenteFormDialog> {
  late final _nomeController = TextEditingController(text: widget.componente?.nome ?? '');
  late TipoComponente _tipo = widget.componente?.tipo ?? TipoComponente.outro;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nomeController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(widget.componente == null ? 'Novo Componente' : 'Editar Componente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Pizza - Massa Grande 35cm',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Tipo', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoComponente.values
                  .map(
                    (opcao) => ChoiceChip(
                      label: Text(formatarTipo(opcao)),
                      selected: _tipo == opcao,
                      onSelected: (_) => setState(() => _tipo = opcao),
                    ),
                  )
                  .toList(),
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
                  widget.onConfirm(_nomeController.text.trim(), _tipo);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
