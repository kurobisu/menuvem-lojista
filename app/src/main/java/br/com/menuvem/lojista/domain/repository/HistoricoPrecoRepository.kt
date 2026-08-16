package br.com.menuvem.lojista.domain.repository

import br.com.menuvem.lojista.domain.model.HistoricoPreco
import kotlinx.coroutines.flow.Flow

/**
 * Contrato abstrato para acesso ao histórico de preços de insumos.
 */
interface HistoricoPrecoRepository {
    fun getHistoricoByInsumo(insumoId: Long): Flow<List<HistoricoPreco>>
    fun getAllInsumosComHistorico(): Flow<List<Long>>   // IDs de insumos que têm histórico
    suspend fun insertHistorico(historico: HistoricoPreco): Long
    suspend fun getUltimosPrecos(insumoId: Long, limite: Int = 3): List<HistoricoPreco>
}
