package br.com.menuvem.lojista.presentation.componentes

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ItemComponente
import br.com.menuvem.lojista.domain.model.ItemComponenteComInsumo
import br.com.menuvem.lojista.domain.model.TipoComponente
import br.com.menuvem.lojista.domain.usecase.DeleteComponenteUseCase
import br.com.menuvem.lojista.domain.usecase.DeleteItemComponenteUseCase
import br.com.menuvem.lojista.domain.usecase.GetComponentesUseCase
import br.com.menuvem.lojista.domain.usecase.SaveComponenteUseCase
import br.com.menuvem.lojista.domain.usecase.SaveItemComponenteUseCase
import br.com.menuvem.lojista.domain.usecase.SearchInsumosUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ComponenteDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val getComponentesUseCase: GetComponentesUseCase,
    private val saveComponenteUseCase: SaveComponenteUseCase,
    private val deleteComponenteUseCase: DeleteComponenteUseCase,
    private val saveItemComponenteUseCase: SaveItemComponenteUseCase,
    private val deleteItemComponenteUseCase: DeleteItemComponenteUseCase,
    private val searchInsumosUseCase: SearchInsumosUseCase
) : ViewModel() {

    val componenteId: Long = savedStateHandle.get<Long>("componenteId") ?: -1L

    private val _uiState = MutableStateFlow(ComponenteDetailUiState())
    val uiState: StateFlow<ComponenteDetailUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    init {
        if (componenteId > 0) {
            observeComponente()
        }
    }

    private fun observeComponente() {
        viewModelScope.launch {
            getComponentesUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { lista ->
                    _uiState.update {
                        it.copy(
                            componente = lista.firstOrNull { c -> c.componente.id == componenteId },
                            isLoading = false
                        )
                    }
                }
        }
    }

    // ── Busca de insumos (bottom sheet) ──────────────────────────────────────

    fun onSearchQueryChanged(query: String) {
        _uiState.update { it.copy(searchQuery = query, isSearching = query.isNotBlank()) }
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(300)
            searchInsumosUseCase(query)
                .catch { e ->
                    _uiState.update { it.copy(isSearching = false, error = e.message) }
                }
                .collectLatest { results ->
                    _uiState.update { it.copy(searchResults = results, isSearching = false) }
                }
        }
    }

    fun onShowAddSheet() {
        _uiState.update { it.copy(showAddSheet = true, searchQuery = "", searchResults = emptyList()) }
    }

    fun onHideAddSheet() {
        _uiState.update { it.copy(showAddSheet = false, searchQuery = "", searchResults = emptyList()) }
    }

    fun addItem(insumo: Insumo, quantidade: Double, perda: Double) {
        viewModelScope.launch {
            saveItemComponenteUseCase(
                ItemComponente(
                    componenteId = componenteId,
                    insumoId = insumo.id,
                    quantidade = quantidade,
                    perdaPercentual = perda
                )
            )
            onHideAddSheet()
        }
    }

    // ── Edição / remoção de item ─────────────────────────────────────────────

    fun onEditItem(item: ItemComponenteComInsumo) {
        _uiState.update { it.copy(itemEmEdicao = item) }
    }

    fun onHideEditItem() {
        _uiState.update { it.copy(itemEmEdicao = null) }
    }

    fun updateItem(item: ItemComponente, quantidade: Double, perda: Double) {
        viewModelScope.launch {
            saveItemComponenteUseCase(item.copy(quantidade = quantidade, perdaPercentual = perda))
            onHideEditItem()
        }
    }

    fun removeItem(item: ItemComponente) {
        viewModelScope.launch { deleteItemComponenteUseCase(item) }
    }

    // ── Dados do componente ──────────────────────────────────────────────────

    fun onShowRenameDialog() {
        _uiState.update { it.copy(showRenameDialog = true) }
    }

    fun onHideRenameDialog() {
        _uiState.update { it.copy(showRenameDialog = false) }
    }

    fun updateComponente(nome: String, tipo: TipoComponente) {
        viewModelScope.launch {
            _uiState.value.componenteModel?.let { atual ->
                saveComponenteUseCase(atual.copy(nome = nome, tipo = tipo))
            }
            onHideRenameDialog()
        }
    }

    // ── Exclusão do componente ───────────────────────────────────────────────

    fun onShowDeleteDialog() {
        _uiState.update { it.copy(showDeleteDialog = true) }
    }

    fun onHideDeleteDialog() {
        _uiState.update { it.copy(showDeleteDialog = false) }
    }

    fun delete() {
        viewModelScope.launch {
            _uiState.value.componenteModel?.let { deleteComponenteUseCase(it) }
            _uiState.update { it.copy(deleted = true) }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}