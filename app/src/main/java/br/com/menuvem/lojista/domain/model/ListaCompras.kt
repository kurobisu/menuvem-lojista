package br.com.menuvem.lojista.domain.model

import java.time.LocalDateTime

/** Status de uma lista de compras. */
enum class StatusLista { ABERTA, FINALIZADA }

/**
 * Modelo de domínio: Lista de Compras.
 */
data class ListaCompras(
    val id: Long = 0,
    val nome: String,
    val dataCriacao: LocalDateTime = LocalDateTime.now(),
    val dataFinalizacao: LocalDateTime? = null,
    val totalGasto: Double = 0.0,
    val status: StatusLista = StatusLista.ABERTA
)
