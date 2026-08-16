package br.com.menuvem.lojista.domain.repository

import br.com.menuvem.lojista.domain.model.ItemLista
import br.com.menuvem.lojista.domain.model.ListaCompras
import kotlinx.coroutines.flow.Flow

/**
 * Contrato abstrato para acesso a Listas de Compras e seus itens.
 */
interface ListaComprasRepository {
    fun getAllListas(): Flow<List<ListaCompras>>
    fun getListaById(id: Long): Flow<ListaCompras?>
    suspend fun insertLista(lista: ListaCompras): Long
    suspend fun updateLista(lista: ListaCompras)
    suspend fun deleteLista(lista: ListaCompras)

    // Itens
    fun getItensByLista(listaId: Long): Flow<List<ItemLista>>
    suspend fun insertItem(item: ItemLista): Long
    suspend fun updateItem(item: ItemLista)
    suspend fun deleteItem(item: ItemLista)
    suspend fun toggleItemComprado(itemId: Long, comprado: Boolean, precoUnitario: Double)
}
