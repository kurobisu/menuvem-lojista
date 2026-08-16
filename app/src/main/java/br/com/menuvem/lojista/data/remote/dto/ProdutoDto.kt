package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.Produto
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.OffsetDateTime

/** Leitura da tabela `produtos`. */
@Serializable
data class ProdutoDto(
    val id: Long,
    val nome: String,
    @SerialName("margem_alvo_percentual") val margemAlvoPercentual: Double,
    @SerialName("preco_venda_atual") val precoVendaAtual: Double? = null,
    @SerialName("data_criacao") val dataCriacao: String
) {
    fun toDomain(): Produto = Produto(
        id = id,
        nome = nome,
        margemAlvoPercentual = margemAlvoPercentual,
        precoVendaAtual = precoVendaAtual,
        dataCriacao = OffsetDateTime.parse(dataCriacao).toLocalDateTime()
    )
}

/** Insert em `produtos` — sem id/user_id/data_criacao (defaults do banco). */
@Serializable
data class ProdutoInsertDto(
    val nome: String,
    @SerialName("margem_alvo_percentual") val margemAlvoPercentual: Double,
    @SerialName("preco_venda_atual") val precoVendaAtual: Double? = null
) {
    companion object {
        fun fromDomain(produto: Produto) = ProdutoInsertDto(
            nome = produto.nome,
            margemAlvoPercentual = produto.margemAlvoPercentual,
            precoVendaAtual = produto.precoVendaAtual
        )
    }
}
