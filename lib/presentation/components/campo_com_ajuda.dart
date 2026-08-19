import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Ícone "?" que abre uma explicação curta com um **exemplo concreto**.
///
/// Termos como "fator de conversão" e "custo por unidade de compra" são
/// óbvios para quem montou o app e opacos para o lojista. Um `helperText`
/// cinza embaixo do campo passa despercebido; um "?" clicável ao lado do
/// campo é percebido e só ocupa espaço quando o usuário quer.
///
/// Use como `suffixIcon` de um `TextField` ou solto ao lado de um rótulo.
class AjudaIconButton extends StatelessWidget {
  const AjudaIconButton({
    super.key,
    required this.titulo,
    required this.explicacao,
    this.exemplo,
  });

  final String titulo;
  final String explicacao;

  /// Exemplo concreto, mostrado em destaque (ex.: "1 kg = 1000 g").
  final String? exemplo;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline, size: 20),
      tooltip: 'O que é isso?',
      visualDensity: VisualDensity.compact,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(explicacao),
              if (exemplo != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: purpleContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exemplo!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: purpleOnContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rótulo de seção com o "?" ao lado — para grupos de campos que não são um
/// `TextField` só (ex.: as duas unidades do insumo).
class RotuloComAjuda extends StatelessWidget {
  const RotuloComAjuda({
    super.key,
    required this.rotulo,
    required this.titulo,
    required this.explicacao,
    this.exemplo,
  });

  final String rotulo;
  final String titulo;
  final String explicacao;
  final String? exemplo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
        AjudaIconButton(
          titulo: titulo,
          explicacao: explicacao,
          exemplo: exemplo,
        ),
      ],
    );
  }
}
