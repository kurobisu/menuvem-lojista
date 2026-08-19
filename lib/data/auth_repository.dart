import 'package:supabase_flutter/supabase_flutter.dart';

/// Fachada de autenticação do app sobre o Supabase Auth (e-mail/senha).
/// A sessão é persistida pelo próprio SDK e restaurada na abertura do app.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  /// Token da sessão atual, usado para salvar a conta no login rápido.
  String? get currentRefreshToken => _client.auth.currentSession?.refreshToken;

  String? get currentEmail => _client.auth.currentUser?.email;

  Future<void> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> signUp(String email, String password) =>
      _client.auth.signUp(email: email.trim(), password: password);

  /// Sai da conta **apenas neste dispositivo** (`SignOutScope.local`).
  ///
  /// O padrão do Supabase é `global`, que revoga os refresh tokens no
  /// servidor — e isso invalidaria os tokens guardados pelo login rápido,
  /// justamente no fluxo em que ele mais é usado (sair e entrar em outra
  /// conta salva). Com escopo local a sessão local é descartada e os tokens
  /// salvos continuam valendo.
  ///
  /// Para revogar de fato (perda do aparelho, por exemplo), use o painel do
  /// Supabase ou remova a conta da lista de login rápido.
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.local);

  /// Restaura uma sessão a partir de um refresh token guardado — é o que faz
  /// o login de um toque nos avatares de contas salvas.
  ///
  /// Lança se o token estiver expirado ou revogado; quem chama trata pedindo
  /// a senha de novo.
  Future<void> entrarComRefreshToken(String refreshToken) =>
      _client.auth.setSession(refreshToken);

  /// Dispara o e-mail de redefinição de senha do Supabase.
  Future<void> enviarResetDeSenha(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}
