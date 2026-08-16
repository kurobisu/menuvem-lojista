package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import javax.inject.Inject

/**
 * Cria ou atualiza um componente (id == 0 → insert).
 */
class SaveComponenteUseCase @Inject constructor(
    private val repository: ComponenteRepository
) {
    suspend operator fun invoke(componente: Componente): Long =
        if (componente.id == 0L) {
            repository.insertComponente(componente)
        } else {
            repository.updateComponente(componente)
            componente.id
        }
}