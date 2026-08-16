package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Leitura da tabela `itens_ficha_tecnica`. */
@Serializable
data class ItemFichaTecnicaDto(
    val id: Long,
    @SerialName("produto_id") val produtoId: Long,
    @SerialName("insumo_id") val insumoId: Long,
    val quantidade: Double,
    @SerialName("perda_percentual") val perdaPercentual: Double
) {
    fun toDomain(): ItemFichaTecnica = ItemFichaTecnica(
        id = id,
        produtoId = produtoId,
        insumoId = insumoId,
        quantidade = quantidade,
        perdaPercentual = perdaPercentual
    )
}

/** Insert em `itens_ficha_tecnica` — sem id/user_id (defaults do banco). */
@Serializable
data class ItemFichaTecnicaInsertDto(
    @SerialName("produto_id") val produtoId: Long,
    @SerialName("insumo_id") val insumoId: Long,
    val quantidade: Double,
    @SerialName("perda_percentual") val perdaPercentual: Double
) {
    companion object {
        fun fromDomain(item: ItemFichaTecnica) = ItemFichaTecnicaInsertDto(
            produtoId = item.produtoId,
            insumoId = item.insumoId,
            quantidade = item.quantidade,
            perdaPercentual = item.perdaPercentual
        )
    }
}
