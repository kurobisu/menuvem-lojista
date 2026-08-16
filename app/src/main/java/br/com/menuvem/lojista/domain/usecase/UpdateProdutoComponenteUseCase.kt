package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ProdutoComponente
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Altera o multiplicador de um componente já aplicado a um produto
 * (ex.: de sabor único para metade — 2 sabores na mesma massa).
 */
class UpdateProdutoComponenteUseCase @Inject constructor(
    private val repository: ProdutoRepository
) {
    suspend operator fun invoke(vinculo: ProdutoComponente, multiplicador: Double) =
        repository.updateProdutoComponente(vinculo.copy(multiplicador = multiplicador))
}