package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class SearchInsumosUseCase @Inject constructor(
    private val repository: InsumoRepository
) {
    operator fun invoke(query: String): Flow<List<Insumo>> =
        if (query.isBlank()) repository.getAllInsumos()
        else repository.searchInsumos(query)
}
