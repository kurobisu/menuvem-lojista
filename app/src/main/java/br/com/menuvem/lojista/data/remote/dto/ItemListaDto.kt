package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.ItemLista
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Leitura da tabela `itens_lista`. */
@Serializable
data class ItemListaDto(
    val id: Long,
    @SerialName("lista_compras_id") val listaComprasId: Long,
    @SerialName("insumo_id") val insumoId: Long? = null,
    @SerialName("nome_item") val nomeItem: String,
    val quantidade: Double,
    val unidade: String,
    @SerialName("preco_unitario") val precoUnitario: Double,
    val comprado: Boolean
) {
    fun toDomain(): ItemLista = ItemLista(
        id = id,
        listaComprasId = listaComprasId,
        insumoId = insumoId,
        nomeItem = nomeItem,
        quantidade = quantidade,
        unidade = unidade,
        precoUnitario = precoUnitario,
        comprado = comprado
    )
}

/** Insert em `itens_lista` — sem id/user_id (defaults do banco). */
@Serializable
data class ItemListaInsertDto(
    @SerialName("lista_compras_id") val listaComprasId: Long,
    @SerialName("insumo_id") val insumoId: Long? = null,
    @SerialName("nome_item") val nomeItem: String,
    val quantidade: Double,
    val unidade: String,
    @SerialName("preco_unitario") val precoUnitario: Double,
    val comprado: Boolean
) {
    companion object {
        fun fromDomain(item: ItemLista) = ItemListaInsertDto(
            listaComprasId = item.listaComprasId,
            insumoId = item.insumoId,
            nomeItem = item.nomeItem,
            quantidade = item.quantidade,
            unidade = item.unidade,
            precoUnitario = item.precoUnitario,
            comprado = item.comprado
        )
    }
}
