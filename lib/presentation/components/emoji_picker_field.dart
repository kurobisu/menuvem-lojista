import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Campo de seleção de emoji: recolhido por padrão (mostra só o ícone de
/// caixa genérico ou o emoji já escolhido) e expande pra grade completa ao
/// tocar. Antes a grade inteira (mais de uma dezena de quadrados) sempre
/// aparecia aberta, competindo por atenção com os campos que realmente
/// importam num formulário curto como o de Componente — relato do dono.
/// Usado no formulário de Insumo, Produto e Componente.
class EmojiPickerField extends StatefulWidget {
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
  State<EmojiPickerField> createState() => _EmojiPickerFieldState();
}

class _EmojiPickerFieldState extends State<EmojiPickerField> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    if (!_expandido) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expandido = true),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EmojiTile(emoji: widget.selecionado, selecionado: false),
            const SizedBox(width: 10),
            Text(
              widget.selecionado == null ? 'Escolher ícone' : 'Trocar ícone',
              style: const TextStyle(
                color: purplePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emoji in widget.opcoes)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              widget.onChanged(widget.selecionado == emoji ? null : emoji);
              setState(() => _expandido = false);
            },
            child: _EmojiTile(
              emoji: emoji,
              selecionado: widget.selecionado == emoji,
            ),
          ),
      ],
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji, required this.selecionado});

  final String? emoji;
  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selecionado ? purpleContainer : Colors.transparent,
        border: Border.all(
          color: selecionado ? purplePrimary : outlineLight,
          width: selecionado ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 20))
          : const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: onSurfaceVariantLight,
            ),
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
