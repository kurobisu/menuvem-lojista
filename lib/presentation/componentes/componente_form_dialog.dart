import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/componente.dart';
import 'componentes_controller.dart' show tiposComponenteProvider;

typedef ComponenteFormConfirm = void Function(String nome, String? tipoNome);

/// Dialog de criação/edição de componente: nome + tipo. O tipo é digitado
/// livremente e reaproveitado (sugestão de autocompletar) entre os
/// componentes já cadastrados pelo usuário — não é mais uma lista fixa.
class ComponenteFormDialog extends ConsumerStatefulWidget {
  const ComponenteFormDialog({
    super.key,
    this.componente,
    this.tipoNomeAtual,
    required this.onConfirm,
  });

  final Componente? componente;
  final String? tipoNomeAtual;
  final ComponenteFormConfirm onConfirm;

  @override
  ConsumerState<ComponenteFormDialog> createState() => _ComponenteFormDialogState();
}

class _ComponenteFormDialogState extends ConsumerState<ComponenteFormDialog> {
  late final _nomeController = TextEditingController(text: widget.componente?.nome ?? '');
  late final _tipoController = TextEditingController(text: widget.tipoNomeAtual ?? '');

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nomeController.text.trim().isNotEmpty;
    final tiposAsync = ref.watch(tiposComponenteProvider);
    final nomesExistentes =
        tiposAsync.maybeWhen(data: (tipos) => tipos.map((t) => t.nome).toList(), orElse: () => const <String>[]);

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
            Autocomplete<String>(
              textEditingController: _tipoController,
              optionsBuilder: (value) {
                if (value.text.trim().isEmpty) return nomesExistentes;
                final q = value.text.toLowerCase();
                return nomesExistentes.where((n) => n.toLowerCase().contains(q));
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Tipo (opcional)',
                    hintText: 'Ex.: Massa, Sabor, Embalagem — crie o seu',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                );
              },
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
                  final tipo = _tipoController.text.trim();
                  widget.onConfirm(_nomeController.text.trim(), tipo.isEmpty ? null : tipo);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
