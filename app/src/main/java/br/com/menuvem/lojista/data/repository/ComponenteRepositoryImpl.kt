package br.com.menuvem.lojista.data.repository

import br.com.menuvem.lojista.data.remote.dto.ComponenteDto
import br.com.menuvem.lojista.data.remote.dto.ComponenteInsertDto
import br.com.menuvem.lojista.data.remote.dto.ItemComponenteDto
import br.com.menuvem.lojista.data.remote.dto.ItemComponenteInsertDto
import br.com.menuvem.lojista.data.remote.tableListFlow
import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.ItemComponente
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class ComponenteRepositoryImpl @Inject constructor(
    private val client: SupabaseClient
) : ComponenteRepository {

    private val refresh = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    override fun getAllComponentes(): Flow<List<Componente>> =
        client.tableListFlow(TABLE_COMPONENTES, refresh) {
            client.postgrest[TABLE_COMPONENTES]
                .select { order("nome", Order.ASCENDING) }
                .decodeList<ComponenteDto>()
        }.map { list -> list.map { it.toDomain() } }

    override fun getAllItensComponente(): Flow<List<ItemComponente>> =
        client.tableListFlow(TABLE_ITENS, refresh) {
            client.postgrest[TABLE_ITENS].select().decodeList<ItemComponenteDto>()
        }.map { list -> list.map { it.toDomain() } }

    override fun getItensByComponente(componenteId: Long): Flow<List<ItemComponente>> =
        client.tableListFlow(TABLE_ITENS, refresh) {
            client.postgrest[TABLE_ITENS]
                .select { filter { eq("componente_id", componenteId) } }
                .decodeList<ItemComponenteDto>()
        }.map { list -> list.map { it.toDomain() } }

    override suspend fun getComponenteById(id: Long): Componente? =
        client.postgrest[TABLE_COMPONENTES]
            .select { filter { eq("id", id) } }
            .decodeSingleOrNull<ComponenteDto>()?.toDomain()

    override suspend fun insertComponente(componente: Componente): Long {
        val inserido = client.postgrest[TABLE_COMPONENTES]
            .insert(ComponenteInsertDto.fromDomain(componente)) {
                select()
            }.decodeSingle<ComponenteDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun updateComponente(componente: Componente) {
        client.postgrest[TABLE_COMPONENTES].update({
            set("nome", componente.nome)
            set("tipo", componente.tipo.name)
        }) {
            filter { eq("id", componente.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteComponente(componente: Componente) {
        client.postgrest[TABLE_COMPONENTES].delete { filter { eq("id", componente.id) } }
        refresh.tryEmit(Unit)
    }

    override suspend fun insertItemComponente(item: ItemComponente): Long {
        val inserido = client.postgrest[TABLE_ITENS]
            .insert(ItemComponenteInsertDto.fromDomain(item)) {
                select()
            }.decodeSingle<ItemComponenteDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun updateItemComponente(item: ItemComponente) {
        client.postgrest[TABLE_ITENS].update({
            set("quantidade", item.quantidade)
            set("perda_percentual", item.perdaPercentual)
        }) {
            filter { eq("id", item.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteItemComponente(item: ItemComponente) {
        client.postgrest[TABLE_ITENS].delete { filter { eq("id", item.id) } }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteItensByComponente(componenteId: Long) {
        client.postgrest[TABLE_ITENS].delete { filter { eq("componente_id", componenteId) } }
        refresh.tryEmit(Unit)
    }

    override suspend fun getItensByInsumo(insumoId: Long): List<ItemComponente> =
        client.postgrest[TABLE_ITENS]
            .select { filter { eq("insumo_id", insumoId) } }
            .decodeList<ItemComponenteDto>()
            .map { it.toDomain() }

    private companion object {
        const val TABLE_COMPONENTES = "componentes"
        const val TABLE_ITENS = "itens_componente"
    }
}