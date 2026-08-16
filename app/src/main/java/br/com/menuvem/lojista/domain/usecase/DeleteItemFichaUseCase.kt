package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Remove um item da ficha técnica.
 */
class DeleteItemFichaUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(item: ItemFichaTecnica) =
        repository.deleteItemFicha(item)
}
