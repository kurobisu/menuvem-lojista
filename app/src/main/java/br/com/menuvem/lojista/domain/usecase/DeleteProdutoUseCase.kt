package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Produto
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Exclui um produto. Os itens da ficha técnica são removidos em cascata (FK).
 */
class DeleteProdutoUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(produto: Produto) =
        repository.deleteProduto(produto)
}
