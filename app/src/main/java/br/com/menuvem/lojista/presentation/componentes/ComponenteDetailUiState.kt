package br.com.menuvem.lojista.presentation.componentes

import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ItemComponenteComInsumo

data class ComponenteDetailUiState(
    val isLoading: Boolean = true,
    val componente: ComponenteComCusto? = null,
    val showAddSheet: Boolean = false,
    val showRenameDialog: Boolean = false,
    val showDeleteDialog: Boolean = false,
    val itemEmEdicao: ItemComponenteComInsumo? = null,
    val searchQuery: String = "",
    val searchResults: List<Insumo> = emptyList(),
    val isSearching: Boolean = false,
    val deleted: Boolean = false,
    val error: String? = null
) {
    val componenteModel: Componente?
        get() = componente?.componente
}