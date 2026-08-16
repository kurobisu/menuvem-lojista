package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemComponenteComInsumo
import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject

/**
 * Lista todos os produtos com o custo calculado a partir da ficha técnica
 * (itens soltos + componentes aplicados, cada um com seu multiplicador).
 * Reativo: reemite quando produtos, insumos (preços), itens de ficha,
 * componentes ou vínculos mudam, recalculando custos e margens.
 */
class GetProdutosComCustoUseCase @Inject constructor(
    private val produtoRepository: ProdutoRepository,
    private val insumoRepository: InsumoRepository,
    private val componenteRepository: ComponenteRepository
) {
    operator fun invoke(): Flow<List<ProdutoComCusto>> =
        combine(
            produtoRepository.getAllProdutos(),
            insumoRepository.getAllInsumos(),
            produtoRepository.getAllItensFicha(),
            produtoRepository.getAllProdutoComponentes(),
            componenteRepository.getAllItensComponente()
        ) { produtos, insumos, itens, vinculos, itensComponente ->
            val insumosById = insumos.associateBy { it.id }
            val itensByProduto = itens.groupBy { it.produtoId }
            val vinculosByProduto = vinculos.groupBy { it.produtoId }
            val itensCompByComponente = itensComponente.groupBy { it.componenteId }
            produtos.map { produto ->
                val itensProduto = itensByProduto[produto.id].orEmpty()
                val custoItens = itensProduto.sumOf { item ->
                    val insumo = insumosById[item.insumoId] ?: return@sumOf 0.0
                    ItemFichaComInsumo(item, insumo).custo
                }
                val vinculosProduto = vinculosByProduto[produto.id].orEmpty()
                val custoComponentes = vinculosProduto.sumOf { vinculo ->
                    itensCompByComponente[vinculo.componenteId].orEmpty().sumOf { item ->
                        val insumo = insumosById[item.insumoId] ?: return@sumOf 0.0
                        ItemComponenteComInsumo(item, insumo).custo * vinculo.multiplicador
                    }
                }
                val quantidadeItens = itensProduto.size + vinculosProduto.sumOf { vinculo ->
                    itensCompByComponente[vinculo.componenteId].orEmpty().size
                }
                ProdutoComCusto(
                    produto = produto,
                    custoTotal = custoItens + custoComponentes,
                    quantidadeItens = quantidadeItens
                )
            }
        }
}