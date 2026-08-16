package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ProdutoComponente
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Remove o vínculo de um componente com um produto (sem apagar o componente).
 */
class DeleteProdutoComponenteUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(vinculo: ProdutoComponente) =
        repository.deleteProdutoComponente(vinculo)
}