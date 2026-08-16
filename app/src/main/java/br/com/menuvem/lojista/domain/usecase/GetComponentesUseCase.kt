package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.domain.model.ItemComponenteComInsumo
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject

/**
 * Lista todos os componentes com seus itens (enriquecidos com insumo) e o
 * custo por inteiro (multiplicador 1). Reativo a mudanças de componentes,
 * itens e preços de insumos.
 */
class GetComponentesUseCase @Inject constructor(
    private val componenteRepository: ComponenteRepository,
    private val insumoRepository: InsumoRepository
) {
    operator fun invoke(): Flow<List<ComponenteComCusto>> =
        combine(
            componenteRepository.getAllComponentes(),
            componenteRepository.getAllItensComponente(),
            insumoRepository.getAllInsumos()
        ) { componentes, itens, insumos ->
            val itensByComponente = itens.groupBy { it.componenteId }
            val insumosById = insumos.associateBy { it.id }
            componentes.map { componente ->
                val itensEnriquecidos = itensByComponente[componente.id].orEmpty()
                    .mapNotNull { item ->
                        insumosById[item.insumoId]?.let { ItemComponenteComInsumo(item, it) }
                    }
                ComponenteComCusto(componente, itensEnriquecidos)
            }
        }
}