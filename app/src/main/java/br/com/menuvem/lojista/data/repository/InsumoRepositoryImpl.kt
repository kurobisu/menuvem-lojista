package br.com.menuvem.lojista.data.repository

import br.com.menuvem.lojista.data.remote.dto.InsumoDto
import br.com.menuvem.lojista.data.remote.dto.InsumoInsertDto
import br.com.menuvem.lojista.data.remote.tableListFlow
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class InsumoRepositoryImpl @Inject constructor(
    private val client: SupabaseClient
) : InsumoRepository {

    private val table get() = client.postgrest[TABLE]
    private val refresh = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    override fun getAllInsumos(): Flow<List<Insumo>> =
        client.tableListFlow(TABLE, refresh) {
            table.select { order("nome", Order.ASCENDING) }.decodeList<InsumoDto>()
        }.map { list -> list.map { it.toDomain() } }

    override fun searchInsumos(query: String): Flow<List<Insumo>> =
        getAllInsumos().map { list ->
            val q = query.trim()
            if (q.isBlank()) list
            else list.filter { it.nome.contains(q, ignoreCase = true) }
        }

    override suspend fun getInsumoById(id: Long): Insumo? =
        table.select { filter { eq("id", id) } }
            .decodeSingleOrNull<InsumoDto>()?.toDomain()

    override suspend fun insertInsumo(insumo: Insumo): Long {
        val inserido = table.insert(InsumoInsertDto.fromDomain(insumo)) {
            select()
        }.decodeSingle<InsumoDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun updateInsumo(insumo: Insumo) {
        table.update({
            set("nome", insumo.nome)
            set("unidade_compra", insumo.unidadeCompra)
            set("unidade_uso", insumo.unidadeUso)
            set("fator_conversao", insumo.fatorConversao)
            set("custo_atual", insumo.custoAtual)
            set("categoria", insumo.categoria.name)
        }) {
            filter { eq("id", insumo.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun updateCustoInsumo(id: Long, novoCusto: Double) {
        table.update({
            set("custo_atual", novoCusto)
        }) {
            filter { eq("id", id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteInsumo(insumo: Insumo) {
        table.delete { filter { eq("id", insumo.id) } }
        refresh.tryEmit(Unit)
    }

    private companion object {
        const val TABLE = "insumos"
    }
}
