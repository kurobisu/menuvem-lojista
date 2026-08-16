package br.com.menuvem.lojista.presentation.history

import br.com.menuvem.lojista.domain.model.HistoricoPreco
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.model.TendenciaPreco
import br.com.menuvem.lojista.presentation.home.InsumoComTendencia

data class PriceHistoryUiState(
    val isLoading: Boolean = true,
    val insumosComTendencia: List<InsumoComTendencia> = emptyList(),
    val error: String? = null
)

data class InsumoHistoryUiState(
    val isLoading: Boolean = true,
    val insumo: Insumo? = null,
    val historico: List<HistoricoPreco> = emptyList(),
    val tendencia: TendenciaPreco = TendenciaPreco.ESTAVEL,
    val error: String? = null
)
