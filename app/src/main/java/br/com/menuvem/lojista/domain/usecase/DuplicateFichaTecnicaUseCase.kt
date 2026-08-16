package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Copia a ficha técnica de um produto para outro, substituindo os itens
 * atuais do destino. Atalho para cadastrar variações (Pizza P/M/G) e combos.
 */
class DuplicateFichaTecnicaUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(produtoOrigemId: Long, produtoDestinoId: Long) {
        if (produtoOrigemId == produtoDestinoId) return
        val itensOrigem = repository.getItensFichaByProduto(produtoOrigemId).first()
        repository.deleteItensFichaByProduto(produtoDestinoId)
        itensOrigem.forEach { item ->
            repository.insertItemFicha(item.copy(id = 0, produtoId = produtoDestinoId))
        }
    }
}
