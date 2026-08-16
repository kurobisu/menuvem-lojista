package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import javax.inject.Inject

class ToggleItemCompradoUseCase @Inject constructor(
    private val repository: ListaComprasRepository
) {
    suspend operator fun invoke(
        itemId: Long,
        comprado: Boolean,
        precoUnitario: Double
    ) {
        repository.toggleItemComprado(itemId, comprado, precoUnitario)
    }
}
