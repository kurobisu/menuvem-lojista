package br.com.menuvem.lojista.presentation.products

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import br.com.menuvem.lojista.domain.usecase.DeleteItemFichaUseCase
import br.com.menuvem.lojista.domain.usecase.DeleteProdutoUseCase
import br.com.menuvem.lojista.domain.usecase.DuplicateFichaTecnicaUseCase
import br.com.menuvem.lojista.domain.usecase.GetFichaTecnicaUseCase
import br.com.menuvem.lojista.domain.usecase.GetProdutosComCustoUseCase
import br.com.menuvem.lojista.domain.usecase.SaveItemFichaUseCase
import br.com.menuvem.lojista.domain.usecase.SaveProdutoUseCase
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
class ProdutoDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val getProdutosComCustoUseCase: GetProdutosComCustoUseCase,
    private val getFichaTecnicaUseCase: GetFichaTecnicaUseCase,
    private val saveProdutoUseCase: SaveProdutoUseCase,
    private val deleteProdutoUseCase: DeleteProdutoUseCase,
    private val saveItemFichaUseCase: SaveItemFichaUseCase,
    private val deleteItemFichaUseCase: DeleteItemFichaUseCase,
    private val duplicateFichaUseCase: DuplicateFichaTecnicaUseCase,
    private val searchInsumosUseCase: SearchInsumosUseCase
) : ViewModel() {

    val produtoId: Long = savedStateHandle.get<Long>("produtoId") ?: -1L

    private val _uiState = MutableStateFlow(ProdutoDetailUiState())
    val uiState: StateFlow<ProdutoDetailUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    init {
        if (produtoId > 0) {
            observeProduto()
            observeFicha()
        }
    }

    private fun observeProduto() {
        viewModelScope.launch {
            getProdutosComCustoUseCase()
                .catch { e -> _uiState.update { it.copy(error = e.message, isLoading = false) } }
                .collectLatest { lista ->
                    val encontrado = lista.firstOrNull { it.produto.id == produtoId }
                    _uiState.update {
                        it.copy(
                            produtoComCusto = encontrado,
                            outrosProdutos = lista.filter { p -> p.produto.id != produtoId }
                                .map { p -> p.produto },
                            isLoading = false
                        )
                    }
                }
        }
    }

    private fun observeFicha() {
        viewModelScope.launch {
            getFichaTecnicaUseCase(produtoId)
                .catch { e -> _uiState.update { it.copy(error = e.message) } }
                .collectLatest { itens ->
                    _uiState.update { it.copy(itensFicha = itens) }
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
            saveItemFichaUseCase(
                ItemFichaTecnica(
                    produtoId = produtoId,
                    insumoId = insumo.id,
                    quantidade = quantidade,
                    perdaPercentual = perda
                )
            )
            onHideAddSheet()
        }
    }

    // ── Edição / remoção de item da ficha ────────────────────────────────────

    fun onEditItem(item: ItemFichaComInsumo) {
        _uiState.update { it.copy(itemEmEdicao = item) }
    }

    fun onHideEditItem() {
        _uiState.update { it.copy(itemEmEdicao = null) }
    }

    fun updateItem(item: ItemFichaTecnica, quantidade: Double, perda: Double) {
        viewModelScope.launch {
            saveItemFichaUseCase(item.copy(quantidade = quantidade, perdaPercentual = perda))
            onHideEditItem()
        }
    }

    fun removeItem(item: ItemFichaTecnica) {
        viewModelScope.launch { deleteItemFichaUseCase(item) }
    }

    // ── Dados do produto ─────────────────────────────────────────────────────

    fun onShowEditDialog() {
        _uiState.update { it.copy(showEditDialog = true) }
    }

    fun onHideEditDialog() {
        _uiState.update { it.copy(showEditDialog = false) }
    }

    fun updateProduto(nome: String, margemAlvo: Double, precoVenda: Double?) {
        viewModelScope.launch {
            _uiState.value.produtoComCusto?.produto?.let { atual ->
                saveProdutoUseCase(
                    atual.copy(
                        nome = nome,
                        margemAlvoPercentual = margemAlvo,
                        precoVendaAtual = precoVenda
                    )
                )
            }
            onHideEditDialog()
        }
    }

    // ── Duplicar ficha de outro produto ──────────────────────────────────────

    fun onShowDuplicateDialog() {
        _uiState.update { it.copy(showDuplicateDialog = true) }
    }

    fun onHideDuplicateDialog() {
        _uiState.update { it.copy(showDuplicateDialog = false) }
    }

    fun duplicateFrom(produtoOrigemId: Long) {
        viewModelScope.launch {
            duplicateFichaUseCase(produtoOrigemId, produtoId)
            onHideDuplicateDialog()
        }
    }

    // ── Exclusão do produto ──────────────────────────────────────────────────

    fun onShowDeleteDialog() {
        _uiState.update { it.copy(showDeleteDialog = true) }
    }

    fun onHideDeleteDialog() {
        _uiState.update { it.copy(showDeleteDialog = false) }
    }

    fun delete() {
        viewModelScope.launch {
            _uiState.value.produtoComCusto?.produto?.let { deleteProdutoUseCase(it) }
            _uiState.update { it.copy(deleted = true) }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
