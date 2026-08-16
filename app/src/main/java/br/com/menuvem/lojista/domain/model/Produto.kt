package br.com.menuvem.lojista.domain.model

import java.time.LocalDateTime

/**
 * Modelo de domínio: Produto (item vendido pela loja, ex.: Pizza Grande de Calabresa).
 * O custo é calculado a partir da ficha técnica (ver [ItemFichaTecnica]).
 *
 * @param margemAlvoPercentual Margem de lucro desejada sobre o preço de venda (%).
 *        Preço sugerido = custo / (1 - margem/100).
 * @param precoVendaAtual Preço praticado hoje (opcional) — usado para comparar a
 *        margem real com a margem-alvo.
 */
data class Produto(
    val id: Long = 0,
    val nome: String,
    val margemAlvoPercentual: Double = 30.0,
    val precoVendaAtual: Double? = null,
    val dataCriacao: LocalDateTime = LocalDateTime.now()
)
