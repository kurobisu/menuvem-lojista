package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.HistoricoPreco
import br.com.menuvem.lojista.domain.repository.HistoricoPrecoRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetHistoricoPrecoUseCase @Inject constructor(
    private val repository: HistoricoPrecoRepository
) {
    operator fun invoke(insumoId: Long): Flow<List<HistoricoPreco>> =
        repository.getHistoricoByInsumo(insumoId)
}
