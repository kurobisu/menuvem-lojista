package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.model.StatusLista
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.OffsetDateTime

/** Leitura da tabela `listas_compras`. */
@Serializable
data class ListaComprasDto(
    val id: Long,
    val nome: String,
    @SerialName("data_criacao") val dataCriacao: String,
    @SerialName("data_finalizacao") val dataFinalizacao: String? = null,
    @SerialName("total_gasto") val totalGasto: Double,
    val status: String
) {
    fun toDomain(): ListaCompras = ListaCompras(
        id = id,
        nome = nome,
        dataCriacao = OffsetDateTime.parse(dataCriacao).toLocalDateTime(),
        dataFinalizacao = dataFinalizacao?.let { OffsetDateTime.parse(it).toLocalDateTime() },
        totalGasto = totalGasto,
        status = runCatching { StatusLista.valueOf(status) }.getOrDefault(StatusLista.ABERTA)
    )
}

/** Insert em `listas_compras` — sem id/user_id/data_criacao (defaults do banco). */
@Serializable
data class ListaComprasInsertDto(
    val nome: String,
    val status: String = "ABERTA"
) {
    companion object {
        fun fromDomain(lista: ListaCompras) = ListaComprasInsertDto(
            nome = lista.nome,
            status = lista.status.name
        )
    }
}
