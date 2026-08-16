package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.ProdutoComponente
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Leitura da tabela `produto_componentes`. */
@Serializable
data class ProdutoComponenteDto(
    val id: Long,
    @SerialName("produto_id") val produtoId: Long,
    @SerialName("componente_id") val componenteId: Long,
    val multiplicador: Double
) {
    fun toDomain(): ProdutoComponente = ProdutoComponente(
        id = id,
        produtoId = produtoId,
        componenteId = componenteId,
        multiplicador = multiplicador
    )
}

/** Insert em `produto_componentes` — sem id/user_id (defaults do banco). */
@Serializable
data class ProdutoComponenteInsertDto(
    @SerialName("produto_id") val produtoId: Long,
    @SerialName("componente_id") val componenteId: Long,
    val multiplicador: Double
) {
    companion object {
        fun fromDomain(vinculo: ProdutoComponente) = ProdutoComponenteInsertDto(
            produtoId = vinculo.produtoId,
            componenteId = vinculo.componenteId,
            multiplicador = vinculo.multiplicador
        )
    }
}