import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/componente.dart';
import '../components/emoji_picker_field.dart';
import '../components/emojis.dart';
import '../components/form_sheet_header.dart';
import 'componentes_controller.dart' show tiposComponenteProvider;

typedef ComponenteFormConfirm =
    void Function(String nome, String? tipoNome, String? emoji);

/// Folha de criação/edição de componente: nome, tipo e ícone. O tipo é
/// digitado livremente e reaproveitado (sugestão de autocompletar) entre os
/// componentes já cadastrados pelo usuário — não é uma lista fixa.
///
/// O botão Salvar fica no cabeçalho fixo (nunca atrás do teclado) — só o
/// conteúdo abaixo rola.
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
  ConsumerState<ComponenteFormDialog> createState() =>
      _ComponenteFormDialogState();
}

class _ComponenteFormDialogState extends ConsumerState<ComponenteFormDialog> {
  late final _nomeController = TextEditingController(
    text: widget.componente?.nome ?? '',
  );
  late final _tipoController = TextEditingController(
    text: widget.tipoNomeAtual ?? '',
  );
  final _tipoFocusNode = FocusNode();
  late String? _emoji = widget.componente?.emoji;

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    _tipoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nomeController.text.trim().isNotEmpty;
    final tiposAsync = ref.watch(tiposComponenteProvider);
    final nomesExistentes = tiposAsync.maybeWhen(
      data: (tipos) => tipos.map((t) => t.nome).toList(),
      orElse: () => const <String>[],
    );

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
              titulo: widget.componente == null
                  ? 'Novo Componente'
                  : 'Editar Componente',
              onCancelar: () => Navigator.of(context).pop(),
              onSalvar: isValid
                  ? () {
                      final tipo = _tipoController.text.trim();
                      widget.onConfirm(
                        _nomeController.text.trim(),
                        tipo.isEmpty ? null : tipo,
                        _emoji,
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
                hintText: 'Ex.: Pizza - Massa Grande 35cm',
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
              opcoes: emojisComponente,
              selecionado: _emoji,
              onChanged: (v) => setState(() => _emoji = v),
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              textEditingController: _tipoController,
              focusNode: _tipoFocusNode,
              optionsBuilder: (value) {
                if (value.text.trim().isEmpty) return nomesExistentes;
                final q = value.text.toLowerCase();
                return nomesExistentes.where(
                  (n) => n.toLowerCase().contains(q),
                );
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
    );
  }
}
