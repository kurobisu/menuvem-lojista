package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.CategoriaInsumo
import br.com.menuvem.lojista.domain.model.Insumo
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.OffsetDateTime

/** Leitura da tabela `insumos`. user_id é omitido — o domínio não precisa dele. */
@Serializable
data class InsumoDto(
    val id: Long,
    val nome: String,
    @SerialName("unidade_compra") val unidadeCompra: String,
    @SerialName("unidade_uso") val unidadeUso: String,
    @SerialName("fator_conversao") val fatorConversao: Double,
    @SerialName("custo_atual") val custoAtual: Double,
    val categoria: String = "INSUMO",
    @SerialName("data_criacao") val dataCriacao: String
) {
    fun toDomain(): Insumo = Insumo(
        id = id,
        nome = nome,
        unidadeCompra = unidadeCompra,
        unidadeUso = unidadeUso,
        fatorConversao = fatorConversao,
        custoAtual = custoAtual,
        dataCriacao = OffsetDateTime.parse(dataCriacao).toLocalDateTime(),
        categoria = runCatching { CategoriaInsumo.valueOf(categoria) }
            .getOrDefault(CategoriaInsumo.INSUMO)
    )
}

/** Insert em `insumos` — sem id/user_id/data_criacao (defaults do banco). */
@Serializable
data class InsumoInsertDto(
    val nome: String,
    @SerialName("unidade_compra") val unidadeCompra: String,
    @SerialName("unidade_uso") val unidadeUso: String,
    @SerialName("fator_conversao") val fatorConversao: Double,
    @SerialName("custo_atual") val custoAtual: Double,
    val categoria: String
) {
    companion object {
        fun fromDomain(insumo: Insumo) = InsumoInsertDto(
            nome = insumo.nome,
            unidadeCompra = insumo.unidadeCompra,
            unidadeUso = insumo.unidadeUso,
            fatorConversao = insumo.fatorConversao,
            custoAtual = insumo.custoAtual,
            categoria = insumo.categoria.name
        )
    }
}
