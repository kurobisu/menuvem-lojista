package br.com.menuvem.lojista.data.remote.dto

import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.TipoComponente
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.OffsetDateTime

/** Leitura da tabela `componentes`. */
@Serializable
data class ComponenteDto(
    val id: Long,
    val nome: String,
    val tipo: String,
    @SerialName("data_criacao") val dataCriacao: String
) {
    fun toDomain(): Componente = Componente(
        id = id,
        nome = nome,
        tipo = runCatching { TipoComponente.valueOf(tipo) }.getOrDefault(TipoComponente.OUTRO),
        dataCriacao = OffsetDateTime.parse(dataCriacao).toLocalDateTime()
    )
}

/** Insert em `componentes` — sem id/user_id/data_criacao (defaults do banco). */
@Serializable
data class ComponenteInsertDto(
    val nome: String,
    val tipo: String
) {
    companion object {
        fun fromDomain(componente: Componente) = ComponenteInsertDto(
            nome = componente.nome,
            tipo = componente.tipo.name
        )
    }
}