import 'package:flutter/widgets.dart';

/// Um passo do tutorial: destaca um widget da tela e explica para que serve.
///
/// [targetKey] aponta para o widget a destacar. Quando é null (ou o widget
/// não está montado), o passo vira só um cartão centralizado — útil para a
/// introdução ("O que é esta tela") e para telas vazias, onde o alvo ainda
/// não existe.
class TutorialStep {
  const TutorialStep({
    required this.titulo,
    required this.descricao,
    this.targetKey,
  });

  final String titulo;
  final String descricao;
  final GlobalKey? targetKey;
}
