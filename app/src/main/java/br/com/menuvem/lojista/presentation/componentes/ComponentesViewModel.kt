package br.com.menuvem.lojista.presentation.componentes

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.domain.model.TipoComponente
import br.com.menuvem.lojista.domain.usecase.DeleteComponenteUseCase
import br.com.menuvem.lojista.domain.usecase.GetComponentesUseCase
import br.com.menuvem.lojista.domain.usecase.SaveComponenteUseCase
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
class ComponentesViewModel @Inject constructor(
    private val getComponentesUseCase: GetComponentesUseCase,
    private val saveComponenteUseCase: SaveComponenteUseCase,
    private val deleteComponenteUseCase: DeleteComponenteUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(ComponentesUiState())
    val uiState: StateFlow<ComponentesUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            getComponentesUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { componentes ->
                    _uiState.update { it.copy(componentes = componentes, isLoading = false) }
                }
        }
    }

    fun onFiltroChange(tipo: TipoComponente?) {
        _uiState.update { it.copy(filtroTipo = tipo) }
    }

    fun onShowForm(componente: Componente? = null) {
        _uiState.update { it.copy(showFormDialog = true, componenteEmEdicao = componente) }
    }

    fun onHideForm() {
        _uiState.update { it.copy(showFormDialog = false, componenteEmEdicao = null) }
    }

    fun save(nome: String, tipo: TipoComponente) {
        viewModelScope.launch {
            val emEdicao = _uiState.value.componenteEmEdicao
            val base = emEdicao ?: Componente(nome = nome, tipo = tipo)
            saveComponenteUseCase(base.copy(nome = nome, tipo = tipo))
            onHideForm()
        }
    }

    fun onShowDeleteConfirm(componente: ComponenteComCusto) {
        _uiState.update { it.copy(componenteParaExcluir = componente) }
    }

    fun onHideDeleteConfirm() {
        _uiState.update { it.copy(componenteParaExcluir = null) }
    }

    fun delete() {
        viewModelScope.launch {
            _uiState.value.componenteParaExcluir?.let { deleteComponenteUseCase(it.componente) }
            _uiState.update { it.copy(componenteParaExcluir = null) }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}