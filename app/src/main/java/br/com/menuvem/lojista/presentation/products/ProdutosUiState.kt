package br.com.menuvem.lojista.presentation.products

import br.com.menuvem.lojista.domain.model.ProdutoComCusto

data class ProdutosUiState(
    val isLoading: Boolean = true,
    val produtos: List<ProdutoComCusto> = emptyList(),
    val showFormDialog: Boolean = false,
    val error: String? = null
)
