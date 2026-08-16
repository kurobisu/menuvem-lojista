package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject

/**
 * Lista todos os produtos com o custo calculado a partir das fichas técnicas.
 * Reativo: reemite quando produtos, insumos (preços) ou itens de ficha mudam,
 * recalculando custos e margens automaticamente.
 */
class GetProdutosComCustoUseCase @Inject constructor(
    private val produtoRepository: ProdutoRepository,
    private val insumoRepository: InsumoRepository
) {
    operator fun invoke(): Flow<List<ProdutoComCusto>> =
        combine(
            produtoRepository.getAllProdutos(),
            insumoRepository.getAllInsumos(),
            produtoRepository.getAllItensFicha()
        ) { produtos, insumos, itens ->
            val insumosById = insumos.associateBy { it.id }
            val itensByProduto = itens.groupBy { it.produtoId }
            produtos.map { produto ->
                val itensProduto = itensByProduto[produto.id].orEmpty()
                val custo = itensProduto.sumOf { item ->
                    val insumo = insumosById[item.insumoId] ?: return@sumOf 0.0
                    ItemFichaComInsumo(item, insumo).custo
                }
                ProdutoComCusto(
                    produto = produto,
                    custoTotal = custo,
                    quantidadeItens = itensProduto.size
                )
            }
        }
}
