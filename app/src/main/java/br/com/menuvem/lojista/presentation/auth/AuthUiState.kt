package br.com.menuvem.lojista.presentation.auth

data class AuthUiState(
    val isSignUpMode: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)
