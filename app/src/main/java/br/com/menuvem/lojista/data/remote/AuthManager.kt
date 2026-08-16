package br.com.menuvem.lojista.data.remote

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Fachada de autenticação do app sobre o Supabase Auth (e-mail/senha).
 * A sessão é persistida pelo próprio SDK e restaurada na abertura do app.
 */
@Singleton
class AuthManager @Inject constructor(
    private val client: SupabaseClient
) {
    /** Estado da sessão: LoadingFromStorage → Authenticated / NotAuthenticated. */
    val sessionStatus: StateFlow<SessionStatus> = client.auth.sessionStatus

    suspend fun signIn(email: String, password: String) =
        client.auth.signInWith(Email) {
            this.email = email
            this.password = password
        }

    suspend fun signUp(email: String, password: String) =
        client.auth.signUpWith(Email) {
            this.email = email
            this.password = password
        }

    suspend fun signOut() = client.auth.signOut()
}
