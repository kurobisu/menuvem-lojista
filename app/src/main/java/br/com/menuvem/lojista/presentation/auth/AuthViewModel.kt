package br.com.menuvem.lojista.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.data.remote.AuthManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authManager: AuthManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    fun toggleMode() {
        _uiState.update { it.copy(isSignUpMode = !it.isSignUpMode, error = null) }
    }

    fun submit(email: String, password: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            runCatching {
                if (_uiState.value.isSignUpMode) authManager.signUp(email.trim(), password)
                else authManager.signIn(email.trim(), password)
            }.onFailure { e ->
                _uiState.update { it.copy(isLoading = false, error = traduzirErro(e)) }
            }.onSuccess {
                // O gate de sessão no MainActivity troca para o app automaticamente
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    private fun traduzirErro(e: Throwable): String = when {
        e.message?.contains("Invalid login", ignoreCase = true) == true ->
            "E-mail ou senha incorretos"
        e.message?.contains("already registered", ignoreCase = true) == true ->
            "Este e-mail já está cadastrado"
        e.message?.contains("Password should be", ignoreCase = true) == true ->
            "A senha precisa ter pelo menos 6 caracteres"
        else -> e.message ?: "Erro ao autenticar — verifique sua conexão"
    }
}
