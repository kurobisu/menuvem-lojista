package br.com.menuvem.lojista.presentation.componentes

import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.domain.model.TipoComponente

data class ComponentesUiState(
    val isLoading: Boolean = true,
    val componentes: List<ComponenteComCusto> = emptyList(),
    val filtroTipo: TipoComponente? = null,
    val showFormDialog: Boolean = false,
    val componenteEmEdicao: Componente? = null,
    val componenteParaExcluir: ComponenteComCusto? = null,
    val error: String? = null
) {
    val componentesFiltrados: List<ComponenteComCusto>
        get() = filtroTipo?.let { tipo -> componentes.filter { it.componente.tipo == tipo } }
            ?: componentes
}