import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tutorial_step.dart';

/// Estado do tutorial em execução. Os passos são sempre os de **uma tela**:
/// não há tour global atravessando rotas, então o controller nunca precisa
/// navegar — o que mantém tudo previsível e independente do go_router.
class TutorialState {
  const TutorialState({this.passos = const [], this.indice = 0});

  final List<TutorialStep> passos;
  final int indice;

  bool get ativo => passos.isNotEmpty;
  TutorialStep? get passoAtual =>
      ativo && indice < passos.length ? passos[indice] : null;
  bool get isUltimo => indice >= passos.length - 1;
}

class TutorialController extends Notifier<TutorialState> {
  @override
  TutorialState build() => const TutorialState();

  void iniciar(List<TutorialStep> passos) {
    if (passos.isEmpty) return;
    state = TutorialState(passos: passos, indice: 0);
  }

  void proximo() {
    if (!state.ativo) return;
    if (state.isUltimo) {
      encerrar();
      return;
    }
    state = TutorialState(passos: state.passos, indice: state.indice + 1);
  }

  void anterior() {
    if (!state.ativo || state.indice == 0) return;
    state = TutorialState(passos: state.passos, indice: state.indice - 1);
  }

  void encerrar() => state = const TutorialState();
}

final tutorialProvider = NotifierProvider<TutorialController, TutorialState>(
  TutorialController.new,
);

/// Marca em `shared_preferences` quais telas já mostraram o tutorial
/// automaticamente, para que ele apareça uma vez só por tela — o botão de
/// ajuda na AppBar continua reabrindo quando o usuário quiser.
class TutorialVistoRepository {
  static String _chave(String tela) => 'tutorial_${tela}_visto';

  Future<bool> jaViu(String tela) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chave(tela)) ?? false;
  }

  Future<void> marcarVisto(String tela) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chave(tela), true);
  }
}

final tutorialVistoRepositoryProvider = Provider(
  (ref) => TutorialVistoRepository(),
);
