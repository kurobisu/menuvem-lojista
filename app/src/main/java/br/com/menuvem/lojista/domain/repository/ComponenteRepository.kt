package br.com.menuvem.lojista.domain.repository

import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.ItemComponente
import kotlinx.coroutines.flow.Flow

/**
 * Contrato abstrato para acesso a Componentes (blocos reutilizáveis de ficha
 * técnica) e seus itens.
 */
interface ComponenteRepository {
    fun getAllComponentes(): Flow<List<Componente>>
    fun getAllItensComponente(): Flow<List<ItemComponente>>
    fun getItensByComponente(componenteId: Long): Flow<List<ItemComponente>>
    suspend fun getComponenteById(id: Long): Componente?
    suspend fun insertComponente(componente: Componente): Long
    suspend fun updateComponente(componente: Componente)
    suspend fun deleteComponente(componente: Componente)
    suspend fun insertItemComponente(item: ItemComponente): Long
    suspend fun updateItemComponente(item: ItemComponente)
    suspend fun deleteItemComponente(item: ItemComponente)
    suspend fun deleteItensByComponente(componenteId: Long)
    suspend fun getItensByInsumo(insumoId: Long): List<ItemComponente>
}