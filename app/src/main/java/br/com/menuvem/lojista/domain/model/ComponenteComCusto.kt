package br.com.menuvem.lojista.domain.model

/**
 * Componente enriquecido com seus itens (com insumo) e o custo por inteiro
 * (multiplicador 1). Usado na biblioteca de componentes e na busca ao montar
 * um produto.
 */
data class ComponenteComCusto(
    val componente: Componente,
    val itens: List<ItemComponenteComInsumo>
) {
    val custo: Double
        get() = itens.sumOf { it.custo }

    val quantidadeItens: Int
        get() = itens.size
}