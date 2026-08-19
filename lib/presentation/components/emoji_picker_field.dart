import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Campo de seleção de emoji: grade de opções, uma selecionada por vez.
/// Usado no formulário de Insumo, Produto e Componente.
class EmojiPickerField extends StatelessWidget {
  const EmojiPickerField({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.onChanged,
  });

  final List<String> opcoes;
  final String? selecionado;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emoji in opcoes)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(selecionado == emoji ? null : emoji),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selecionado == emoji ? purpleContainer : Colors.transparent,
                border: Border.all(
                  color: selecionado == emoji ? purplePrimary : outlineLight,
                  width: selecionado == emoji ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
      ],
    );
  }
}

/// Avatar circular com o emoji do item (ou o ícone padrão [fallback] se não
/// tiver emoji definido), usado nas listas e cabeçalhos de detalhe.
class EmojiAvatar extends StatelessWidget {
  const EmojiAvatar({
    super.key,
    required this.emoji,
    required this.fallback,
    this.radius = 20,
  });

  final String? emoji;
  final IconData fallback;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: purpleContainer,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: radius))
          : Icon(fallback, color: purpleOnContainer, size: radius),
    );
  }
}
