package br.com.menuvem.lojista.presentation.history

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.usecase.GetHistoricoPrecoUseCase
import br.com.menuvem.lojista.domain.usecase.GetInsumosUseCase
import br.com.menuvem.lojista.domain.usecase.GetTendenciaPrecoUseCase
import br.com.menuvem.lojista.presentation.home.InsumoComTendencia
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PriceHistoryViewModel @Inject constructor(
    private val getInsumosUseCase: GetInsumosUseCase,
    private val getTendenciaUseCase: GetTendenciaPrecoUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(PriceHistoryUiState())
    val uiState: StateFlow<PriceHistoryUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            getInsumosUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { insumos ->
                    val comTendencia = insumos.mapNotNull { insumo ->
                        runCatching {
                            InsumoComTendencia(
                                insumo = insumo,
                                tendencia = getTendenciaUseCase(insumo.id),
                                ultimoPreco = insumo.custoAtual
                            )
                        }.getOrNull()
                    }
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            insumosComTendencia = comTendencia.sortedBy { it.insumo.nome }
                        )
                    }
                }
        }
    }
}

@HiltViewModel
class InsumoHistoryViewModel @Inject constructor(
    private val savedStateHandle: SavedStateHandle,
    private val insumoRepository: InsumoRepository,
    private val getHistoricoUseCase: GetHistoricoPrecoUseCase,
    private val getTendenciaUseCase: GetTendenciaPrecoUseCase
) : ViewModel() {

    private val insumoId: Long = savedStateHandle.get<Long>("insumoId") ?: -1L

    private val _uiState = MutableStateFlow(InsumoHistoryUiState())
    val uiState: StateFlow<InsumoHistoryUiState> = _uiState.asStateFlow()

    init {
        if (insumoId > 0) {
            loadData()
        }
    }

    private fun loadData() {
        viewModelScope.launch {
            // Insumo
            val insumo = insumoRepository.getInsumoById(insumoId)
            _uiState.update { it.copy(insumo = insumo) }

            // Histórico
            getHistoricoUseCase(insumoId)
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { historico ->
                    val tendencia = getTendenciaUseCase(insumoId)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            historico = historico,
                            tendencia = tendencia
                        )
                    }
                }
        }
    }
}
