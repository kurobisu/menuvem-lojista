package br.com.menuvem.lojista.presentation.products

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.model.Produto
import br.com.menuvem.lojista.domain.usecase.GetProdutosComCustoUseCase
import br.com.menuvem.lojista.domain.usecase.SaveProdutoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ProdutosViewModel @Inject constructor(
    private val getProdutosComCustoUseCase: GetProdutosComCustoUseCase,
    private val saveProdutoUseCase: SaveProdutoUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProdutosUiState())
    val uiState: StateFlow<ProdutosUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            getProdutosComCustoUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { produtos ->
                    _uiState.update { it.copy(produtos = produtos, isLoading = false) }
                }
        }
    }

    fun onShowForm() {
        _uiState.update { it.copy(showFormDialog = true) }
    }

    fun onHideForm() {
        _uiState.update { it.copy(showFormDialog = false) }
    }

    fun createProduto(
        nome: String,
        margemAlvo: Double,
        precoVenda: Double?,
        onCreated: (Long) -> Unit
    ) {
        viewModelScope.launch {
            val id = saveProdutoUseCase(
                Produto(
                    nome = nome,
                    margemAlvoPercentual = margemAlvo,
                    precoVendaAtual = precoVenda
                )
            )
            _uiState.update { it.copy(showFormDialog = false) }
            onCreated(id)
        }
    }
}
