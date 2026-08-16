package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ProdutoComponente
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Vincula um componente a um produto com o multiplicador aplicado.
 * Ex.: sabor único = 1.0; 2 sabores na mesma massa = 0.5; 3 sabores = 1/3.
 */
class AddComponenteToProdutoUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(produtoId: Long, componenteId: Long, multiplicador: Double): Long =
        repository.insertProdutoComponente(
            ProdutoComponente(
                produtoId = produtoId,
                componenteId = componenteId,
                multiplicador = multiplicador
            )
        )
}