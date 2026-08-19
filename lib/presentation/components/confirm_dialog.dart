import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Pergunta antes de uma ação destrutiva ou que sobrescreve dados (excluir,
/// duplicar, copiar por cima de algo). Sem confirmação, uma ação que demora
/// um instante pra refletir na tela (rede, Realtime) parecia "não ter
/// funcionado" e convidava a tocar de novo — no caso de duplicar, isso criava
/// cópias repetidas.
///
/// Retorna true só se o usuário confirmar; false em qualquer outro caso
/// (cancelou, fechou o diálogo tocando fora).
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String rotuloConfirmar = 'Confirmar',
  bool destrutivo = true,
}) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            rotuloConfirmar,
            style: destrutivo ? const TextStyle(color: errorRed) : null,
          ),
        ),
      ],
    ),
  );
  return confirmou ?? false;
}
