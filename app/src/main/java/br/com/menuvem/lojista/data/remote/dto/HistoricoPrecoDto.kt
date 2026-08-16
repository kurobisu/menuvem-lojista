package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.HistoricoPreco
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.OffsetDateTime

/** Leitura da tabela `historico_precos`. */
@Serializable
data class HistoricoPrecoDto(
    val id: Long,
    @SerialName("insumo_id") val insumoId: Long,
    val preco: Double,
    val data: String,
    @SerialName("lista_compras_id") val listaComprasId: Long,
    @SerialName("lista_compras_nome") val listaComprasNome: String
) {
    fun toDomain(): HistoricoPreco = HistoricoPreco(
        id = id,
        insumoId = insumoId,
        preco = preco,
        data = OffsetDateTime.parse(data).toLocalDateTime(),
        listaComprasId = listaComprasId,
        listaComprasNome = listaComprasNome
    )
}

/** Insert em `historico_precos` — sem id/user_id/data (defaults do banco). */
@Serializable
data class HistoricoPrecoInsertDto(
    @SerialName("insumo_id") val insumoId: Long,
    val preco: Double,
    @SerialName("lista_compras_id") val listaComprasId: Long,
    @SerialName("lista_compras_nome") val listaComprasNome: String
) {
    companion object {
        fun fromDomain(h: HistoricoPreco) = HistoricoPrecoInsertDto(
            insumoId = h.insumoId,
            preco = h.preco,
            listaComprasId = h.listaComprasId,
            listaComprasNome = h.listaComprasNome
        )
    }
}
