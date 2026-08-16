package br.com.menuvem.lojista.data.repository

import br.com.menuvem.lojista.data.remote.dto.ItemFichaTecnicaDto
import br.com.menuvem.lojista.data.remote.dto.ItemFichaTecnicaInsertDto
import br.com.menuvem.lojista.data.remote.dto.ProdutoDto
import br.com.menuvem.lojista.data.remote.dto.ProdutoInsertDto
import br.com.menuvem.lojista.data.remote.tableListFlow
import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import br.com.menuvem.lojista.domain.model.Produto
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import javax.inject.Inject

class ProdutoRepositoryImpl @Inject constructor(
    private val client: SupabaseClient
) : ProdutoRepository {

    private val refresh = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    override fun getAllProdutos(): Flow<List<Produto>> =
        client.tableListFlow(TABLE_PRODUTOS, refresh) {
            client.postgrest[TABLE_PRODUTOS]
                .select { order("nome", Order.ASCENDING) }
                .decodeList<ProdutoDto>()
        }.map { list -> list.map { it.toDomain() } }

    override suspend fun getProdutoById(id: Long): Produto? =
        client.postgrest[TABLE_PRODUTOS]
            .select { filter { eq("id", id) } }
            .decodeSingleOrNull<ProdutoDto>()?.toDomain()

    override suspend fun insertProduto(produto: Produto): Long {
        val inserido = client.postgrest[TABLE_PRODUTOS]
            .insert(ProdutoInsertDto.fromDomain(produto)) {
                select()
            }.decodeSingle<ProdutoDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun updateProduto(produto: Produto) {
        client.postgrest[TABLE_PRODUTOS].update({
            set("nome", produto.nome)
            set("margem_alvo_percentual", produto.margemAlvoPercentual)
            set(
                "preco_venda_atual",
                produto.precoVendaAtual?.let { JsonPrimitive(it) } ?: JsonNull
            )
        }) {
            filter { eq("id", produto.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteProduto(produto: Produto) {
        client.postgrest[TABLE_PRODUTOS].delete { filter { eq("id", produto.id) } }
        refresh.tryEmit(Unit)
    }

    // ── Ficha técnica ────────────────────────────────────────────────────────

    override fun getItensFichaByProduto(produtoId: Long): Flow<List<ItemFichaTecnica>> =
        client.tableListFlow(TABLE_FICHA, refresh) {
            client.postgrest[TABLE_FICHA]
                .select { filter { eq("produto_id", produtoId) } }
                .decodeList<ItemFichaTecnicaDto>()
        }.map { list -> list.map { it.toDomain() } }

    override fun getAllItensFicha(): Flow<List<ItemFichaTecnica>> =
        client.tableListFlow(TABLE_FICHA, refresh) {
            client.postgrest[TABLE_FICHA]
                .select()
                .decodeList<ItemFichaTecnicaDto>()
        }.map { list -> list.map { it.toDomain() } }

    override suspend fun getItensFichaByInsumo(insumoId: Long): List<ItemFichaTecnica> =
        client.postgrest[TABLE_FICHA]
            .select { filter { eq("insumo_id", insumoId) } }
            .decodeList<ItemFichaTecnicaDto>()
            .map { it.toDomain() }

    override suspend fun insertItemFicha(item: ItemFichaTecnica): Long {
        val inserido = client.postgrest[TABLE_FICHA]
            .insert(ItemFichaTecnicaInsertDto.fromDomain(item)) {
                select()
            }.decodeSingle<ItemFichaTecnicaDto>()
        refresh.tryEmit(Unit)
        return inserido.id
    }

    override suspend fun updateItemFicha(item: ItemFichaTecnica) {
        client.postgrest[TABLE_FICHA].update({
            set("quantidade", item.quantidade)
            set("perda_percentual", item.perdaPercentual)
        }) {
            filter { eq("id", item.id) }
        }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteItemFicha(item: ItemFichaTecnica) {
        client.postgrest[TABLE_FICHA].delete { filter { eq("id", item.id) } }
        refresh.tryEmit(Unit)
    }

    override suspend fun deleteItensFichaByProduto(produtoId: Long) {
        client.postgrest[TABLE_FICHA].delete { filter { eq("produto_id", produtoId) } }
        refresh.tryEmit(Unit)
    }

    private companion object {
        const val TABLE_PRODUTOS = "produtos"
        const val TABLE_FICHA = "itens_ficha_tecnica"
    }
}
