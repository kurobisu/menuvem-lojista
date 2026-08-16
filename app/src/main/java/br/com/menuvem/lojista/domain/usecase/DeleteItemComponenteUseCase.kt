package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemComponente
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import javax.inject.Inject

/**
 * Remove um item de componente.
 */
class DeleteItemComponenteUseCase @Inject constructor(
    private val repository: ComponenteRepository
) {
    suspend operator fun invoke(item: ItemComponente) =
        repository.deleteItemComponente(item)
}