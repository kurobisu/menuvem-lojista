package br.com.menuvem.lojista.domain.model

/**
 * Componente aplicado a um produto, enriquecido com os dados do componente e
 * seus itens (com insumo) para exibição e cálculo de custo no produto.
 *
 * @param custo Custo da parcela deste componente no produto =
 *        soma dos itens (por inteiro) × multiplicador do vínculo.
 */
data class ProdutoComponenteCompleto(
    val vinculo: ProdutoComponente,
    val componente: Componente,
    val itens: List<ItemComponenteComInsumo>
) {
    val custo: Double
        get() = itens.sumOf { it.custo } * vinculo.multiplicador

    val quantidadeItens: Int
        get() = itens.size
}