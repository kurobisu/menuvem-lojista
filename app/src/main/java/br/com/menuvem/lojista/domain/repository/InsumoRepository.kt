package br.com.menuvem.lojista.domain.repository

import br.com.menuvem.lojista.domain.model.Insumo
import kotlinx.coroutines.flow.Flow

/**
 * Contrato abstrato para acesso a Insumos.
 * A implementação concreta usa Room; futuras versões podem usar API Menuvem.
 */
interface InsumoRepository {
    fun getAllInsumos(): Flow<List<Insumo>>
    fun searchInsumos(query: String): Flow<List<Insumo>>
    suspend fun getInsumoById(id: Long): Insumo?
    suspend fun insertInsumo(insumo: Insumo): Long
    suspend fun updateInsumo(insumo: Insumo)
    suspend fun updateCustoInsumo(id: Long, novoCusto: Double)
    suspend fun deleteInsumo(insumo: Insumo)
}
