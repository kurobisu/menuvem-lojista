package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.ItemLista
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import javax.inject.Inject

class AddItemToListaUseCase @Inject constructor(
    private val repository: ListaComprasRepository
) {
    /**
     * Adiciona um item livre (não vinculado a insumo) à lista.
     */
    suspend operator fun invoke(
        listaId: Long,
        nomeItem: String,
        quantidade: Double,
        unidade: String,
        precoUnitario: Double = 0.0,
        insumo: Insumo? = null
    ): Long {
        val item = ItemLista(
            listaComprasId = listaId,
            insumoId = insumo?.id,
            nomeItem = if (insumo != null) insumo.nome else nomeItem.trim(),
            quantidade = quantidade,
            unidade = if (insumo != null) insumo.unidadeCompra else unidade,
            precoUnitario = if (insumo != null && precoUnitario <= 0.0) insumo.custoAtual else precoUnitario
        )
        return repository.insertItem(item)
    }
}
