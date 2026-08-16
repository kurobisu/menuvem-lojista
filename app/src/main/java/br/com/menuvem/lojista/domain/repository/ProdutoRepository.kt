package br.com.menuvem.lojista.domain.repository

import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import br.com.menuvem.lojista.domain.model.Produto
import br.com.menuvem.lojista.domain.model.ProdutoComponente
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

    fun getProdutoComponentesByProduto(produtoId: Long): Flow<List<ProdutoComponente>>
    fun getAllProdutoComponentes(): Flow<List<ProdutoComponente>>
    suspend fun getProdutoComponentesByProdutoOnce(produtoId: Long): List<ProdutoComponente>
    suspend fun insertProdutoComponente(vinculo: ProdutoComponente): Long
    suspend fun updateProdutoComponente(vinculo: ProdutoComponente)
    suspend fun deleteProdutoComponente(vinculo: ProdutoComponente)
    suspend fun deleteProdutoComponentesByProduto(produtoId: Long)
}
