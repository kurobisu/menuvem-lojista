package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import javax.inject.Inject

class CreateListaComprasUseCase @Inject constructor(
    private val repository: ListaComprasRepository
) {
    /**
     * Cria uma nova lista de compras com o nome fornecido.
     * @return ID da lista criada.
     */
    suspend operator fun invoke(nome: String): Long {
        val lista = ListaCompras(nome = nome.trim())
        return repository.insertLista(lista)
    }
}
