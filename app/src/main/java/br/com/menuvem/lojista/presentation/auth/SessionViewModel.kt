package br.com.menuvem.lojista.presentation.auth

import androidx.lifecycle.ViewModel
import br.com.menuvem.lojista.data.remote.AuthManager
import dagger.hilt.android.lifecycle.HiltViewModel
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

/**
 * Expõe o estado da sessão para o gate do MainActivity:
 * LoadingFromStorage → splash; Authenticated → app; demais → login.
 */
@HiltViewModel
class SessionViewModel @Inject constructor(
    authManager: AuthManager
) : ViewModel() {
    val sessionStatus: StateFlow<SessionStatus> = authManager.sessionStatus
}
