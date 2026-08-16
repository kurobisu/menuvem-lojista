package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import javax.inject.Inject

/**
 * Cria ou atualiza um insumo (id == 0 → insert). Retorna o id do insumo.
 * O custo informado manualmente funciona como override do preço vindo do
 * histórico de compras.
 */
class SaveInsumoUseCase @Inject constructor(
    private val repository: InsumoRepository
) {
    suspend operator fun invoke(insumo: Insumo): Long =
        if (insumo.id == 0L) {
            repository.insertInsumo(insumo)
        } else {
            repository.updateInsumo(insumo)
            insumo.id
        }
}
