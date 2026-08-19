import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Cabeçalho padrão dos formulários em folha/dialog (`showResponsiveFormSheet`):
/// alça de arraste + Cancelar/título/Salvar.
///
/// Salvar e Cancelar usam `FilledButton`/`OutlinedButton` em vez do
/// `TextButton` simples que havia antes em cada tela — texto solto sem fundo
/// nem borda não lia como botão (relato do dono ao testar o formulário de
/// Componente). Repetido em 5 telas antes desta extração; centralizar aqui
/// evita que a próxima tela reintroduza o TextButton antigo por engano.
class FormSheetHeader extends StatelessWidget {
  const FormSheetHeader({
    super.key,
    required this.titulo,
    required this.onCancelar,
    required this.onSalvar,
    this.rotuloSalvar = 'Salvar',
  });

  final String titulo;
  final VoidCallback onCancelar;
  final VoidCallback? onSalvar;
  final String rotuloSalvar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: onCancelar,
              child: const Text('Cancelar'),
            ),
            Expanded(
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: onSalvar,
              child: Text(rotuloSalvar),
            ),
          ],
        ),
      ],
    );
  }
}
