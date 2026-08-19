import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tutorial_controller.dart';
import 'tutorial_passos.dart';

/// Botão de tutorial da AppBar. Dispara os passos **da tela onde está** e,
/// na primeira visita àquela tela, abre o tutorial sozinho.
///
/// A exibição automática é por tela (flag própria no shared_preferences), em
/// vez de um tour único no primeiro acesso ao app: o usuário aprende cada
/// tela quando chega nela, no contexto em que a explicação faz sentido.
class TutorialButton extends ConsumerStatefulWidget {
  const TutorialButton({super.key, required this.tela, this.autoExibir = true});

  /// Identificador da tela (ver [TutorialTela]).
  final String tela;

  /// Abrir sozinho na primeira visita.
  final bool autoExibir;

  @override
  ConsumerState<TutorialButton> createState() => _TutorialButtonState();
}

class _TutorialButtonState extends ConsumerState<TutorialButton> {
  @override
  void initState() {
    super.initState();
    if (widget.autoExibir) _talvezExibirAutomaticamente();
  }

  Future<void> _talvezExibirAutomaticamente() async {
    final repo = ref.read(tutorialVistoRepositoryProvider);
    if (await repo.jaViu(widget.tela)) return;
    if (!mounted) return;
    // Espera a tela assentar (listas carregando, alvos ainda sem tamanho).
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await repo.marcarVisto(widget.tela);
    if (!mounted) return;
    _iniciar();
  }

  void _iniciar() {
    final passos = passosDaTela(widget.tela);
    if (passos.isEmpty) return;
    ref.read(tutorialProvider.notifier).iniciar(passos);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Como usar esta tela',
      onPressed: _iniciar,
    );
  }
}
