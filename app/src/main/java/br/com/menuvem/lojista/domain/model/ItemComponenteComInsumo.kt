package br.com.menuvem.lojista.domain.model

/**
 * Item de componente enriquecido com o insumo correspondente, usado no
 * cálculo de custo (quantidade × custoPorUnidadeUso, com perda).
 */
data class ItemComponenteComInsumo(
    val item: ItemComponente,
    val insumo: Insumo
) {
    /** Custo do item por inteiro (multiplicador 1), considerando perda. */
    val custo: Double
        get() {
            val perda = item.perdaPercentual.coerceIn(0.0, 99.9)
            return item.quantidade * insumo.custoPorUnidadeUso / (1.0 - perda / 100.0)
        }
}