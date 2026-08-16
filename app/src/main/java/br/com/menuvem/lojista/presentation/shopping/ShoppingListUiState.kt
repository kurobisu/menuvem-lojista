package br.com.menuvem.lojista.presentation.shopping

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ItemLista
import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.model.TendenciaPreco

data class ShoppingListUiState(
    val isLoading: Boolean = true,
    val lista: ListaCompras? = null,
    val itens: List<ItemLista> = emptyList(),
    val tendencias: Map<Long, TendenciaPreco> = emptyMap(), // insumoId -> tendencia
    val searchQuery: String = "",
    val searchResults: List<Insumo> = emptyList(),
    val isSearching: Boolean = false,
    val showAddSheet: Boolean = false,
    val showFinishDialog: Boolean = false,
    val isFinishing: Boolean = false,
    val finishedSuccess: Boolean = false,
    val error: String? = null
) {
    val totalGasto: Double get() = itens.filter { it.comprado }.sumOf { it.precoTotal }
    val totalPrevisto: Double get() = itens.sumOf { it.precoTotal }
    val itensComprados: Int get() = itens.count { it.comprado }
    val totalItens: Int get() = itens.size
}

data class ShoppingListsUiState(
    val isLoading: Boolean = true,
    val listas: List<ListaCompras> = emptyList(),
    val error: String? = null
)
