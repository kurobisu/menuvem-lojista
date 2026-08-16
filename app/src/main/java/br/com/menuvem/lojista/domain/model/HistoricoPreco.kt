package br.com.menuvem.lojista.domain.model

import java.time.LocalDateTime

/**
 * Modelo de domínio: Registro histórico de preço de um insumo.
 *
 * @param preco           Preço pago por unidade de COMPRA do insumo.
 * @param listaComprasId  Lista de compras de origem deste registro.
 */
data class HistoricoPreco(
    val id: Long = 0,
    val insumoId: Long,
    val preco: Double,
    val data: LocalDateTime = LocalDateTime.now(),
    val listaComprasId: Long,
    val listaComprasNome: String = ""
)
