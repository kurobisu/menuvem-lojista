package br.com.menuvem.lojista.domain.model

/**
 * Item de um [Componente]: um insumo com a quantidade usada quando o
 * componente é aplicado por inteiro (multiplicador 1).
 *
 * @param quantidade Quantidade do insumo, na unidadeUso do insumo.
 * @param perdaPercentual Perda/rendimento do preparo (%). Padrão 0.
 */
data class ItemComponente(
    val id: Long = 0,
    val componenteId: Long,
    val insumoId: Long,
    val quantidade: Double,
    val perdaPercentual: Double = 0.0
)