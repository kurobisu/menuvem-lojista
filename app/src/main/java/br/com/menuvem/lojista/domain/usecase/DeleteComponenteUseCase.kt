package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import javax.inject.Inject

/**
 * Exclui um componente (remove também os vínculos com produtos — cascade no banco).
 */
class DeleteComponenteUseCase @Inject constructor(
    private val repository: ComponenteRepository
) {
    suspend operator fun invoke(componente: Componente) =
        repository.deleteComponente(componente)
}