package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Produto
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Cria ou atualiza um produto (id == 0 → insert). Retorna o id do produto.
 */
class SaveProdutoUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(produto: Produto): Long =
        if (produto.id == 0L) {
            repository.insertProduto(produto)
        } else {
            repository.updateProduto(produto)
            produto.id
        }
}
