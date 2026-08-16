package br.com.menuvem.lojista.data.repository

import br.com.menuvem.lojista.data.remote.dto.ItemListaDto
import br.com.menuvem.lojista.data.remote.dto.ItemListaInsertDto
import br.com.menuvem.lojista.data.remote.dto.ListaComprasDto
import br.com.menuvem.lojista.data.remote.dto.ListaComprasInsertDto
import br.com.menuvem.lojista.data.remote.tableListFlow
import br.com.menuvem.lojista.domain.model.ItemLista
import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import java.time.ZoneOffset
import javax.inject.Inject

class ListaComprasRepositoryImpl @Inject constructor(
    private val client: SupabaseClient
) : ListaComprasRepository {

    private val refresh = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    override fun getAllListas(): Flow<List<ListaCompras>> =
        client.tableListFlow(TABLE_LISTAS, refresh) {
            client.postgrest[TABLE_LISTAS]
                .select { order("data_criacao", Order.DESCENDING) }
                .decodeList<ListaComprasDto>()
        }.map { list -> list.map { it.toDomain() } }

    override fun getListaById(id: Long): Flow<ListaCompras?> =
        getAllListas().map { list -> list.firstOrNull { it.id == id } }

    override suspend fun insertLista(lista: ListaCompras): Long {
        val inserida = client.postgrest[TABLE_LISTAS]
            .insert(ListaComprasInsertDto.fromDomain(lista)) {
                select()
            }.decodeSingle<ListaComprasDto>()
        refresh.tryEmit(Unit)
        return inserida.id
    }

    override suspend fun updateLista(lista: ListaCompras) {
        client.postgrest[TABLE_LISTAS].update({
            set("nome", lista.nome)
            set("status", lista.status.name)
            set("total_gasto", lista.totalGasto)
            set(
                "data_finalizacao",
                lista.dataFinalizacao
                    ?.let { JsonPrimitive(it.atOffset(ZoneOffset.UTC).toString()) }
                    ?: JsonNull
            )
        }) {
            filter { eq("id", lista.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteLista(lista: ListaCompras) {
        client.postgrest[TABLE_LISTAS].delete { filter { eq("id", lista.id) } }
        refresh.tryEmit(Unit)
    }

    // ── Itens ────────────────────────────────────────────────────────────────

    override fun getItensByLista(listaId: Long): Flow<List<ItemLista>> =
        client.tableListFlow(TABLE_ITENS, refresh) {
            client.postgrest[TABLE_ITENS]
                .select {
                    filter { eq("lista_compras_id", listaId) }
                    order("id", Order.ASCENDING)
                }
                .decodeList<ItemListaDto>()
        }.map { list -> list.map { it.toDomain() } }

    override suspend fun insertItem(item: ItemLista): Long {
        val inserido = client.postgrest[TABLE_ITENS]
            .insert(ItemListaInsertDto.fromDomain(item)) {
                select()
            }.decodeSingle<ItemListaDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun updateItem(item: ItemLista) {
        client.postgrest[TABLE_ITENS].update({
            set("insumo_id", item.insumoId?.let { JsonPrimitive(it) } ?: JsonNull)
            set("nome_item", item.nomeItem)
            set("quantidade", item.quantidade)
            set("unidade", item.unidade)
            set("preco_unitario", item.precoUnitario)
            set("comprado", item.comprado)
        }) {
            filter { eq("id", item.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteItem(item: ItemLista) {
        client.postgrest[TABLE_ITENS].delete { filter { eq("id", item.id) } }
        refresh.tryEmit(Unit)
    }

    override suspend fun toggleItemComprado(itemId: Long, comprado: Boolean, precoUnitario: Double) {
        client.postgrest[TABLE_ITENS].update({
            set("comprado", comprado)
            set("preco_unitario", precoUnitario)
        }) {
            filter { eq("id", itemId) }
        }
        refresh.tryEmit(Unit)
    }

    private companion object {
        const val TABLE_LISTAS = "listas_compras"
        const val TABLE_ITENS = "itens_lista"
    }
}
