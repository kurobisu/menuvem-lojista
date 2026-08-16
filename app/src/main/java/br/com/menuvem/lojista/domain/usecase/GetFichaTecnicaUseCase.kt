package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject

/**
 * Ficha técnica de um produto: itens com o insumo correspondente e o custo
 * de cada item (considerando perda/rendimento). Reativo a mudanças de preço
 * dos insumos.
 */
class GetFichaTecnicaUseCase @Inject constructor(
    private val produtoRepository: ProdutoRepository,
    private val insumoRepository: InsumoRepository
) {
    operator fun invoke(produtoId: Long): Flow<List<ItemFichaComInsumo>> =
        combine(
            produtoRepository.getItensFichaByProduto(produtoId),
            insumoRepository.getAllInsumos()
        ) { itens, insumos ->
            val insumosById = insumos.associateBy { it.id }
            itens.mapNotNull { item ->
                insumosById[item.insumoId]?.let { ItemFichaComInsumo(item, it) }
            }
        }
}
