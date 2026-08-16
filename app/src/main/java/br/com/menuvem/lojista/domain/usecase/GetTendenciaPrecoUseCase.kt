package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.TendenciaPreco
import br.com.menuvem.lojista.domain.repository.HistoricoPrecoRepository
import javax.inject.Inject

class GetTendenciaPrecoUseCase @Inject constructor(
    private val repository: HistoricoPrecoRepository
) {
    /**
     * Retorna a tendência de preço do insumo com base nas últimas 3 compras.
     */
    suspend operator fun invoke(insumoId: Long): TendenciaPreco {
        val ultimos = repository.getUltimosPrecos(insumoId, limite = 3)
        val precos = ultimos.map { it.preco }
        return TendenciaPreco.calcular(precos)
    }
}
