package br.com.menuvem.lojista.domain.model

/**
 * Vínculo de um [Componente] a um [Produto], com o multiplicador aplicado.
 *
 * @param multiplicador Fração do componente usada no produto. Ex.: sabor único
 *        numa pizza = 1.0 (inteiro); 2 sabores = 0.5 (metade); 3 sabores = 1/3.
 *        Massa/base e embalagem normalmente usam 1.0.
 */
data class ProdutoComponente(
    val id: Long = 0,
    val produtoId: Long,
    val componenteId: Long,
    val multiplicador: Double = 1.0
)