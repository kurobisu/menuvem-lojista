package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.ItemComponente
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Leitura da tabela `itens_componente`. */
@Serializable
data class ItemComponenteDto(
    val id: Long,
    @SerialName("componente_id") val componenteId: Long,
    @SerialName("insumo_id") val insumoId: Long,
    val quantidade: Double,
    @SerialName("perda_percentual") val perdaPercentual: Double
) {
    fun toDomain(): ItemComponente = ItemComponente(
        id = id,
        componenteId = componenteId,
        insumoId = insumoId,
        quantidade = quantidade,
        perdaPercentual = perdaPercentual
    )
}

/** Insert em `itens_componente` — sem id/user_id (defaults do banco). */
@Serializable
data class ItemComponenteInsertDto(
    @SerialName("componente_id") val componenteId: Long,
    @SerialName("insumo_id") val insumoId: Long,
    val quantidade: Double,
    @SerialName("perda_percentual") val perdaPercentual: Double
) {
    companion object {
        fun fromDomain(item: ItemComponente) = ItemComponenteInsertDto(
            componenteId = item.componenteId,
            insumoId = item.insumoId,
            quantidade = item.quantidade,
            perdaPercentual = item.perdaPercentual
        )
    }
}