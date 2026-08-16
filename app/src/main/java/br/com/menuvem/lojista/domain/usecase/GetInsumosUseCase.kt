package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetInsumosUseCase @Inject constructor(
    private val repository: InsumoRepository
) {
    operator fun invoke(): Flow<List<Insumo>> = repository.getAllInsumos()
}
