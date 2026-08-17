import 'package:supabase_flutter/supabase_flutter.dart';

/// Fachada de autenticação do app sobre o Supabase Auth (e-mail/senha).
/// A sessão é persistida pelo próprio SDK e restaurada na abertura do app.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn(String email, String password) => _client.auth
      .signInWithPassword(email: email.trim(), password: password);

  Future<void> signUp(String email, String password) =>
      _client.auth.signUp(email: email.trim(), password: password);

  Future<void> signOut() => _client.auth.signOut();
}
