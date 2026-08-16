package br.com.menuvem.lojista.data.repository

import br.com.menuvem.lojista.data.remote.dto.HistoricoPrecoDto
import br.com.menuvem.lojista.data.remote.dto.HistoricoPrecoInsertDto
import br.com.menuvem.lojista.data.remote.tableListFlow
import br.com.menuvem.lojista.domain.model.HistoricoPreco
import br.com.menuvem.lojista.domain.repository.HistoricoPrecoRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class HistoricoPrecoRepositoryImpl @Inject constructor(
    private val client: SupabaseClient
) : HistoricoPrecoRepository {

    private val table get() = client.postgrest[TABLE]
    private val refresh = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    override fun getHistoricoByInsumo(insumoId: Long): Flow<List<HistoricoPreco>> =
        client.tableListFlow(TABLE, refresh) {
            table.select {
                filter { eq("insumo_id", insumoId) }
                order("data", Order.ASCENDING)
            }.decodeList<HistoricoPrecoDto>()
        }.map { list -> list.map { it.toDomain() } }

    override fun getAllInsumosComHistorico(): Flow<List<Long>> =
        client.tableListFlow(TABLE, refresh) {
            table.select().decodeList<HistoricoPrecoDto>()
        }.map { list -> list.map { it.insumoId }.distinct() }

    override suspend fun insertHistorico(historico: HistoricoPreco): Long {
        val inserido = table.insert(HistoricoPrecoInsertDto.fromDomain(historico)) {
            select()
        }.decodeSingle<HistoricoPrecoDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun getUltimosPrecos(insumoId: Long, limite: Int): List<HistoricoPreco> =
        table.select {
            filter { eq("insumo_id", insumoId) }
            order("data", Order.DESCENDING)
            limit(limite.toLong())
        }.decodeList<HistoricoPrecoDto>().map { it.toDomain() }

    private companion object {
        const val TABLE = "historico_precos"
    }
}
