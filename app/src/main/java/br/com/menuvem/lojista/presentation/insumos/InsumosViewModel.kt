package br.com.menuvem.lojista.presentation.insumos

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.model.CategoriaInsumo
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.usecase.DeleteInsumoUseCase
import br.com.menuvem.lojista.domain.usecase.GetInsumosUseCase
import br.com.menuvem.lojista.domain.usecase.SaveInsumoUseCase
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
class InsumosViewModel @Inject constructor(
    private val getInsumosUseCase: GetInsumosUseCase,
    private val saveInsumoUseCase: SaveInsumoUseCase,
    private val deleteInsumoUseCase: DeleteInsumoUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(InsumosUiState())
    val uiState: StateFlow<InsumosUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            getInsumosUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { insumos ->
                    _uiState.update { it.copy(insumos = insumos, isLoading = false) }
                }
        }
    }

    fun onFiltroChange(categoria: CategoriaInsumo?) {
        _uiState.update { it.copy(filtroCategoria = categoria) }
    }

    fun onShowForm(insumo: Insumo? = null) {
        _uiState.update { it.copy(showFormDialog = true, insumoEmEdicao = insumo) }
    }

    fun onHideForm() {
        _uiState.update { it.copy(showFormDialog = false, insumoEmEdicao = null) }
    }

    fun save(
        nome: String,
        categoria: CategoriaInsumo,
        unidadeCompra: String,
        unidadeUso: String,
        fatorConversao: Double,
        custoAtual: Double
    ) {
        viewModelScope.launch {
            val emEdicao = _uiState.value.insumoEmEdicao
            val base = emEdicao ?: Insumo(
                nome = nome,
                unidadeCompra = unidadeCompra,
                unidadeUso = unidadeUso,
                fatorConversao = fatorConversao
            )
            saveInsumoUseCase(
                base.copy(
                    nome = nome,
                    categoria = categoria,
                    unidadeCompra = unidadeCompra,
                    unidadeUso = unidadeUso,
                    fatorConversao = fatorConversao,
                    custoAtual = custoAtual
                )
            )
            onHideForm()
        }
    }

    fun onShowDeleteConfirm(insumo: Insumo) {
        _uiState.update { it.copy(insumoParaExcluir = insumo) }
    }

    fun onHideDeleteConfirm() {
        _uiState.update { it.copy(insumoParaExcluir = null) }
    }

    fun delete() {
        viewModelScope.launch {
            val insumo = _uiState.value.insumoParaExcluir ?: return@launch
            val erro = deleteInsumoUseCase(insumo)
            _uiState.update { it.copy(insumoParaExcluir = null, error = erro) }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
