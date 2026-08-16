package br.com.menuvem.lojista.domain.model

/**
 * Modelo de domínio: ItemFichaTecnica — um insumo que compõe um [Produto],
 * com a quantidade usada por porção.
 *
 * @param quantidade Quantidade do insumo por porção, na unidadeUso do insumo.
 * @param perdaPercentual Perda/rendimento do preparo (%). Ex.: 20 significa que
 *        o insumo rende 80%, encarecendo a porção real. Padrão 0.
 */
data class ItemFichaTecnica(
    val id: Long = 0,
    val produtoId: Long,
    val insumoId: Long,
    val quantidade: Double,
    val perdaPercentual: Double = 0.0
)
