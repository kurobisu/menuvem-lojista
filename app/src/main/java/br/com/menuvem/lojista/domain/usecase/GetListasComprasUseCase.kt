package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetListasComprasUseCase @Inject constructor(
    private val repository: ListaComprasRepository
) {
    operator fun invoke(): Flow<List<ListaCompras>> = repository.getAllListas()
}
