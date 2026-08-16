package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Copia a ficha técnica de um produto para outro, substituindo os itens
 * atuais do destino (itens soltos e componentes aplicados, com multiplicador).
 * Atalho para cadastrar variações (Pizza P/M/G), combos e cópias que depois
 * podem ser editadas (ex.: "Hambúrguer de Calabresa" usando a mesma base).
 */
class DuplicateFichaTecnicaUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(produtoOrigemId: Long, produtoDestinoId: Long) {
        if (produtoOrigemId == produtoDestinoId) return
        val itensOrigem = repository.getItensFichaByProduto(produtoOrigemId).first()
        val componentesOrigem = repository.getProdutoComponentesByProdutoOnce(produtoOrigemId)
        repository.deleteItensFichaByProduto(produtoDestinoId)
        repository.deleteProdutoComponentesByProduto(produtoDestinoId)
        itensOrigem.forEach { item ->
            repository.insertItemFicha(item.copy(id = 0, produtoId = produtoDestinoId))
        }
        componentesOrigem.forEach { vinculo ->
            repository.insertProdutoComponente(vinculo.copy(id = 0, produtoId = produtoDestinoId))
        }
    }
}