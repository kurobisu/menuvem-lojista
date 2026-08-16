package br.com.menuvem.lojista.presentation.products

import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.model.Produto
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.domain.model.ProdutoComponenteCompleto

data class ProdutoDetailUiState(
    val isLoading: Boolean = true,
    val produtoComCusto: ProdutoComCusto? = null,
    val itensFicha: List<ItemFichaComInsumo> = emptyList(),
    val componentes: List<ProdutoComponenteCompleto> = emptyList(),
    val todosComponentes: List<ComponenteComCusto> = emptyList(),
    val outrosProdutos: List<Produto> = emptyList(),
    val showAddSheet: Boolean = false,
    val showAddComponenteSheet: Boolean = false,
    val showEditDialog: Boolean = false,
    val showDuplicateDialog: Boolean = false,
    val showDeleteDialog: Boolean = false,
    val itemEmEdicao: ItemFichaComInsumo? = null,
    val componenteEmEdicao: ProdutoComponenteCompleto? = null,
    val searchQuery: String = "",
    val searchResults: List<Insumo> = emptyList(),
    val isSearching: Boolean = false,
    val deleted: Boolean = false,
    val error: String? = null
)