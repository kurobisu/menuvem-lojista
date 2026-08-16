package br.com.menuvem.lojista.domain.repository

import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import br.com.menuvem.lojista.domain.model.Produto
import kotlinx.coroutines.flow.Flow

/**
 * Contrato abstrato para acesso a Produtos e suas fichas técnicas.
 * A implementação concreta usa Room; futuras versões podem usar API Menuvem.
 */
interface ProdutoRepository {
    fun getAllProdutos(): Flow<List<Produto>>
    suspend fun getProdutoById(id: Long): Produto?
    suspend fun insertProduto(produto: Produto): Long
    suspend fun updateProduto(produto: Produto)
    suspend fun deleteProduto(produto: Produto)

    fun getItensFichaByProduto(produtoId: Long): Flow<List<ItemFichaTecnica>>
    fun getAllItensFicha(): Flow<List<ItemFichaTecnica>>
    suspend fun getItensFichaByInsumo(insumoId: Long): List<ItemFichaTecnica>
    suspend fun insertItemFicha(item: ItemFichaTecnica): Long
    suspend fun updateItemFicha(item: ItemFichaTecnica)
    suspend fun deleteItemFicha(item: ItemFichaTecnica)
    suspend fun deleteItensFichaByProduto(produtoId: Long)
}
