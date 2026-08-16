package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemFichaTecnica
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Adiciona ou atualiza um item da ficha técnica (id == 0 → insert).
 */
class SaveItemFichaUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(item: ItemFichaTecnica): Long =
        if (item.id == 0L) {
            repository.insertItemFicha(item)
        } else {
            repository.updateItemFicha(item)
            item.id
        }
}
