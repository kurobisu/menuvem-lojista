package br.com.menuvem.lojista.domain.model

/**
 * Produto com o custo calculado a partir da ficha técnica,
 * mais as regras de precificação por margem-alvo.
 */
data class ProdutoComCusto(
    val produto: Produto,
    val custoTotal: Double,
    val quantidadeItens: Int
) {
    /** Preço sugerido = custo ÷ (1 − margem/100). Zero se não houver custo. */
    val precoSugerido: Double
        get() = if (custoTotal > 0 && produto.margemAlvoPercentual < 100.0)
            custoTotal / (1.0 - produto.margemAlvoPercentual / 100.0)
        else 0.0

    /** Margem real sobre o preço de venda atual (%). Null se não há preço praticado. */
    val margemRealPercentual: Double?
        get() = produto.precoVendaAtual?.takeIf { it > 0 }?.let { preco ->
            (preco - custoTotal) / preco * 100.0
        }

    /** Verdadeiro quando há preço praticado e a margem real ficou abaixo da margem-alvo. */
    val margemAbaixoDaMeta: Boolean
        get() = margemRealPercentual?.let { it < produto.margemAlvoPercentual } ?: false
}
