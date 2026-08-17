import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/repository_providers.dart';

class AuthUiState {
  final bool isSignUpMode;
  final bool isLoading;
  final String? error;

  const AuthUiState({
    this.isSignUpMode = false,
    this.isLoading = false,
    this.error,
  });

  AuthUiState copyWith({
    bool? isSignUpMode,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthUiState(
      isSignUpMode: isSignUpMode ?? this.isSignUpMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  void toggleMode() {
    state = state.copyWith(isSignUpMode: !state.isSignUpMode, clearError: true);
  }

  Future<void> submit(String email, String senha) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (state.isSignUpMode) {
        await repo.signUp(email, senha);
      } else {
        await repo.signIn(email, senha);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _traduzirErro(e));
    }
  }

  String _traduzirErro(Object e) {
    final msg = e.toString();
    if (msg.toLowerCase().contains('invalid login')) {
      return 'E-mail ou senha incorretos';
    }
    if (msg.toLowerCase().contains('already registered') ||
        msg.toLowerCase().contains('user already registered')) {
      return 'Este e-mail já está cadastrado';
    }
    if (msg.toLowerCase().contains('password should be') ||
        msg.toLowerCase().contains('password')) {
      return 'A senha precisa ter pelo menos 6 caracteres';
    }
    return 'Erro ao autenticar — verifique sua conexão';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthUiState>(
  AuthController.new,
);
