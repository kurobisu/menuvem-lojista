package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemComponenteComInsumo
import br.com.menuvem.lojista.domain.model.ProdutoComponenteCompleto
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject

/**
 * Componentes aplicados a um produto, enriquecidos com os dados do componente
 * e seus itens (com insumo) e o custo da parcela no produto (× multiplicador).
 * Reativo a mudanças de vínculos, componentes, itens e preços de insumos.
 */
class GetProdutoComponentesUseCase @Inject constructor(
    private val produtoRepository: ProdutoRepository,
    private val componenteRepository: ComponenteRepository,
    private val insumoRepository: InsumoRepository
) {
    operator fun invoke(produtoId: Long): Flow<List<ProdutoComponenteCompleto>> =
        combine(
            produtoRepository.getProdutoComponentesByProduto(produtoId),
            componenteRepository.getAllComponentes(),
            componenteRepository.getAllItensComponente(),
            insumoRepository.getAllInsumos()
        ) { vinculos, componentes, itens, insumos ->
            val componentesById = componentes.associateBy { it.id }
            val itensByComponente = itens.groupBy { it.componenteId }
            val insumosById = insumos.associateBy { it.id }
            vinculos.mapNotNull { vinculo ->
                val componente = componentesById[vinculo.componenteId] ?: return@mapNotNull null
                val itensEnriquecidos = itensByComponente[vinculo.componenteId].orEmpty()
                    .mapNotNull { item ->
                        insumosById[item.insumoId]?.let { ItemComponenteComInsumo(item, it) }
                    }
                ProdutoComponenteCompleto(vinculo, componente, itensEnriquecidos)
            }
        }
}