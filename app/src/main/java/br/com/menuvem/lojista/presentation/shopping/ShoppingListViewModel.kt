package br.com.menuvem.lojista.presentation.shopping

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ItemLista
import br.com.menuvem.lojista.domain.model.TendenciaPreco
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import br.com.menuvem.lojista.domain.usecase.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ShoppingListViewModel @Inject constructor(
    private val savedStateHandle: SavedStateHandle,
    private val listaComprasRepository: ListaComprasRepository,
    private val addItemUseCase: AddItemToListaUseCase,
    private val toggleItemUseCase: ToggleItemCompradoUseCase,
    private val finalizarUseCase: FinalizarCompraUseCase,
    private val searchInsumosUseCase: SearchInsumosUseCase,
    private val getTendenciaUseCase: GetTendenciaPrecoUseCase
) : ViewModel() {

    val listaId: Long = savedStateHandle.get<Long>("listaId") ?: -1L

    private val _uiState = MutableStateFlow(ShoppingListUiState())
    val uiState: StateFlow<ShoppingListUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    init {
        if (listaId > 0) {
            observeLista()
            observeItens()
        }
    }

    private fun observeLista() {
        viewModelScope.launch {
            listaComprasRepository.getListaById(listaId)
                .collectLatest { lista ->
                    _uiState.update { it.copy(lista = lista, isLoading = lista == null) }
                }
        }
    }

    private fun observeItens() {
        viewModelScope.launch {
            listaComprasRepository.getItensByLista(listaId)
                .collectLatest { itens ->
                    val tendencias = itens
                        .mapNotNull { it.insumoId }
                        .distinct()
                        .associateWith { insumoId ->
                            runCatching { getTendenciaUseCase(insumoId) }
                                .getOrDefault(TendenciaPreco.ESTAVEL)
                        }
                    _uiState.update {
                        it.copy(itens = itens, tendencias = tendencias, isLoading = false)
                    }
                }
        }
    }

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

    fun clearSearch() {
        _uiState.update { it.copy(searchQuery = "", searchResults = emptyList(), isSearching = false) }
    }

    fun onShowAddSheet() {
        _uiState.update { it.copy(showAddSheet = true) }
        clearSearch()
    }

    fun onHideAddSheet() {
        _uiState.update { it.copy(showAddSheet = false) }
        clearSearch()
    }

    fun addItem(
        nomeItem: String,
        quantidade: Double,
        unidade: String,
        precoUnitario: Double,
        insumo: Insumo? = null
    ) {
        viewModelScope.launch {
            addItemUseCase(
                listaId = listaId,
                nomeItem = nomeItem,
                quantidade = quantidade,
                unidade = unidade,
                precoUnitario = precoUnitario,
                insumo = insumo
            )
            onHideAddSheet()
        }
    }

    fun toggleItem(itemId: Long, comprado: Boolean, preco: Double) {
        viewModelScope.launch {
            toggleItemUseCase(itemId, comprado, preco)
        }
    }

    fun deleteItem(item: ItemLista) {
        viewModelScope.launch {
            listaComprasRepository.deleteItem(item)
        }
    }

    fun onShowFinishDialog() {
        _uiState.update { it.copy(showFinishDialog = true) }
    }

    fun onDismissFinishDialog() {
        _uiState.update { it.copy(showFinishDialog = false) }
    }

    fun finalizarCompra() {
        viewModelScope.launch {
            _uiState.update { it.copy(isFinishing = true, showFinishDialog = false) }
            runCatching { finalizarUseCase(listaId) }
                .onSuccess { _uiState.update { it.copy(isFinishing = false, finishedSuccess = true) } }
                .onFailure { e -> _uiState.update { it.copy(isFinishing = false, error = e.message) } }
        }
    }

    fun clearSuccess() {
        _uiState.update { it.copy(finishedSuccess = false) }
    }
}

@HiltViewModel
class ShoppingListsViewModel @Inject constructor(
    private val getListasUseCase: GetListasComprasUseCase,
    private val createListaUseCase: CreateListaComprasUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(ShoppingListsUiState())
    val uiState: StateFlow<ShoppingListsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            getListasUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { listas ->
                    _uiState.update { it.copy(listas = listas, isLoading = false) }
                }
        }
    }

    fun createLista(nome: String, onCreated: (Long) -> Unit) {
        viewModelScope.launch {
            val id = createListaUseCase(nome)
            onCreated(id)
        }
    }
}
