package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemComponente
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import javax.inject.Inject

/**
 * Adiciona ou atualiza um item de componente (id == 0 → insert).
 */
class SaveItemComponenteUseCase @Inject constructor(
    private val repository: ComponenteRepository
) {
    suspend operator fun invoke(item: ItemComponente): Long =
        if (item.id == 0L) {
            repository.insertItemComponente(item)
        } else {
            repository.updateItemComponente(item)
            item.id
        }
}