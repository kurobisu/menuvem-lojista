package br.com.menuvem.lojista.presentation.insumos

import br.com.menuvem.lojista.domain.model.CategoriaInsumo
import br.com.menuvem.lojista.domain.model.Insumo

data class InsumosUiState(
    val isLoading: Boolean = true,
    val insumos: List<Insumo> = emptyList(),
    val filtroCategoria: CategoriaInsumo? = null,
    val showFormDialog: Boolean = false,
    val insumoEmEdicao: Insumo? = null,
    val insumoParaExcluir: Insumo? = null,
    val error: String? = null
) {
    val insumosFiltrados: List<Insumo>
        get() = filtroCategoria?.let { cat -> insumos.filter { it.categoria == cat } } ?: insumos
}
