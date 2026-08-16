package br.com.menuvem.lojista.presentation.home

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.domain.model.TendenciaPreco

data class HomeUiState(
    val isLoading: Boolean = true,
    val ultimaLista: ListaCompras? = null,
    val todasListas: List<ListaCompras> = emptyList(),
    val insumosComTendencia: List<InsumoComTendencia> = emptyList(),
    val produtosComCusto: List<ProdutoComCusto> = emptyList(),
    val error: String? = null
) {
    /** Produtos com preço praticado cuja margem real caiu abaixo da margem-alvo. */
    val produtosAbaixoDaMeta: List<ProdutoComCusto>
        get() = produtosComCusto.filter { it.margemAbaixoDaMeta }
}

data class InsumoComTendencia(
    val insumo: Insumo,
    val tendencia: TendenciaPreco,
    val ultimoPreco: Double
)
