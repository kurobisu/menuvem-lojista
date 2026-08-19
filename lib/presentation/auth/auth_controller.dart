import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/contas_salvas_repository.dart';
import '../../providers/repository_providers.dart';

class AuthUiState {
  final bool isSignUpMode;
  final bool isLoading;
  final String? error;

  /// Mensagem de sucesso (ex.: e-mail de recuperação enviado).
  final String? aviso;

  /// Marcado por padrão: o dono pediu login rápido como comportamento normal.
  final bool salvarLogin;

  final bool senhaVisivel;
  final List<ContaSalva> contasSalvas;

  const AuthUiState({
    this.isSignUpMode = false,
    this.isLoading = false,
    this.error,
    this.aviso,
    this.salvarLogin = true,
    this.senhaVisivel = false,
    this.contasSalvas = const [],
  });

  AuthUiState copyWith({
    bool? isSignUpMode,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? aviso,
    bool clearAviso = false,
    bool? salvarLogin,
    bool? senhaVisivel,
    List<ContaSalva>? contasSalvas,
  }) {
    return AuthUiState(
      isSignUpMode: isSignUpMode ?? this.isSignUpMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      aviso: clearAviso ? null : (aviso ?? this.aviso),
      salvarLogin: salvarLogin ?? this.salvarLogin,
      senhaVisivel: senhaVisivel ?? this.senhaVisivel,
      contasSalvas: contasSalvas ?? this.contasSalvas,
    );
  }
}

class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() {
    _carregarContas();
    return const AuthUiState();
  }

  Future<void> _carregarContas() async {
    final contas = await ref.read(contasSalvasRepositoryProvider).listar();
    state = state.copyWith(contasSalvas: contas);
  }

  void toggleMode() {
    state = state.copyWith(
      isSignUpMode: !state.isSignUpMode,
      clearError: true,
      clearAviso: true,
    );
  }

  void toggleSenhaVisivel() {
    state = state.copyWith(senhaVisivel: !state.senhaVisivel);
  }

  void setSalvarLogin(bool valor) {
    state = state.copyWith(salvarLogin: valor);
  }

  Future<void> submit(String email, String senha) async {
    state = state.copyWith(isLoading: true, clearError: true, clearAviso: true);
    final auth = ref.read(authRepositoryProvider);
    try {
      if (state.isSignUpMode) {
        await auth.signUp(email, senha);
      } else {
        await auth.signIn(email, senha);
      }
      await _salvarContaSeMarcado();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _traduzirErro(e));
    }
  }

  /// Login de um toque a partir de uma conta salva.
  ///
  /// Se o token estiver expirado ou revogado, deixa o e-mail preenchido e
  /// pede a senha — a conta continua salva para que uma nova entrada renove
  /// o token.
  Future<String?> entrarComContaSalva(ContaSalva conta) async {
    state = state.copyWith(isLoading: true, clearError: true, clearAviso: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .entrarComRefreshToken(conta.refreshToken);
      await _salvarContaSeMarcado();
      state = state.copyWith(isLoading: false);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:
            'A sessão salva de ${conta.email} expirou. Digite a senha para entrar de novo.',
      );
      // devolve o e-mail para a tela preencher o campo
      return conta.email;
    }
  }

  Future<void> _salvarContaSeMarcado() async {
    final auth = ref.read(authRepositoryProvider);
    final email = auth.currentEmail;
    final token = auth.currentRefreshToken;
    final contasSalvas = ref.read(contasSalvasRepositoryProvider);

    if (!state.salvarLogin || email == null || token == null) return;

    await contasSalvas.salvar(ContaSalva(email: email, refreshToken: token));
    state = state.copyWith(contasSalvas: await contasSalvas.listar());
  }

  Future<void> removerConta(String email) async {
    final contasSalvas = ref.read(contasSalvasRepositoryProvider);
    await contasSalvas.remover(email);
    state = state.copyWith(contasSalvas: await contasSalvas.listar());
  }

  Future<void> resetarSenha(String email) async {
    if (!email.contains('@')) {
      state = state.copyWith(
        error: 'Digite o e-mail da conta no campo acima para recuperar a senha',
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearAviso: true);
    try {
      await ref.read(authRepositoryProvider).enviarResetDeSenha(email);
      state = state.copyWith(
        isLoading: false,
        aviso:
            'E-mail de recuperação enviado para $email. Verifique a caixa de entrada e o spam.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _traduzirErro(e));
    }
  }

  String _traduzirErro(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login')) {
      return 'E-mail ou senha incorretos';
    }
    if (msg.contains('already registered')) {
      return 'Este e-mail já está cadastrado';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar — veja a caixa de entrada';
    }
    if (msg.contains('password')) {
      return 'A senha precisa ter pelo menos 6 caracteres';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Muitas tentativas seguidas. Aguarde um pouco e tente de novo';
    }
    return 'Erro ao autenticar — verifique sua conexão';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthUiState>(
  AuthController.new,
);
