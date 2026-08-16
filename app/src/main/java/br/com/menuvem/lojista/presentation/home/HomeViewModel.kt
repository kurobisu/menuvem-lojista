package br.com.menuvem.lojista.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.data.remote.AuthManager
import br.com.menuvem.lojista.domain.usecase.GetInsumosUseCase
import br.com.menuvem.lojista.domain.usecase.GetListasComprasUseCase
import br.com.menuvem.lojista.domain.usecase.GetProdutosComCustoUseCase
import br.com.menuvem.lojista.domain.usecase.GetTendenciaPrecoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getListasUseCase: GetListasComprasUseCase,
    private val getInsumosUseCase: GetInsumosUseCase,
    private val getTendenciaUseCase: GetTendenciaPrecoUseCase,
    private val getProdutosComCustoUseCase: GetProdutosComCustoUseCase,
    private val authManager: AuthManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    fun signOut() {
        viewModelScope.launch { authManager.signOut() }
    }

    private fun loadData() {
        viewModelScope.launch {
            combine(
                getListasUseCase(),
                getInsumosUseCase(),
                getProdutosComCustoUseCase()
            ) { listas, insumos, produtos ->
                Triple(listas, insumos, produtos)
            }.collectLatest { (listas, insumos, produtos) ->
                val ultimaLista = listas.firstOrNull()

                // Calcula tendências para cada insumo com histórico
                val insumosComTendencia = insumos.mapNotNull { insumo ->
                    runCatching {
                        val tendencia = getTendenciaUseCase(insumo.id)
                        InsumoComTendencia(
                            insumo = insumo,
                            tendencia = tendencia,
                            ultimoPreco = insumo.custoAtual
                        )
                    }.getOrNull()
                }

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        ultimaLista = ultimaLista,
                        todasListas = listas,
                        insumosComTendencia = insumosComTendencia,
                        produtosComCusto = produtos
                    )
                }
            }
        }
    }
}
