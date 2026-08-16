package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.HistoricoPreco
import br.com.menuvem.lojista.domain.model.StatusLista
import br.com.menuvem.lojista.domain.repository.HistoricoPrecoRepository
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import kotlinx.coroutines.flow.first
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * Finaliza uma lista de compras:
 * 1. Coleta snapshot dos itens e da lista.
 * 2. Para cada item comprado vinculado a insumo:
 *    a. Registra o histórico de preço.
 *    b. Atualiza o custo atual do insumo (LIFO — último preço pago).
 * 3. Calcula o total gasto e marca a lista como FINALIZADA.
 */
class FinalizarCompraUseCase @Inject constructor(
    private val listaRepository: ListaComprasRepository,
    private val insumoRepository: InsumoRepository,
    private val historicoRepository: HistoricoPrecoRepository
) {
    suspend operator fun invoke(listaId: Long) {
        // Snapshot único dos dados via Flow.first()
        val itens = listaRepository.getItensByLista(listaId).first()
        val lista = listaRepository.getListaById(listaId).first() ?: return

        val totalGasto = itens
            .filter { it.comprado }
            .sumOf { it.precoTotal }

        // Para cada item comprado com insumo vinculado e preço registrado
        itens
            .filter { it.comprado && it.insumoId != null && it.precoUnitario > 0 }
            .forEach { item ->
                // 1. Registra no histórico
                historicoRepository.insertHistorico(
                    HistoricoPreco(
                        insumoId = item.insumoId!!,
                        preco = item.precoUnitario,
                        data = LocalDateTime.now(),
                        listaComprasId = listaId,
                        listaComprasNome = lista.nome
                    )
                )
                // 2. Atualiza custo base (LIFO)
                insumoRepository.updateCustoInsumo(item.insumoId, item.precoUnitario)
            }

        // 3. Finaliza a lista
        listaRepository.updateLista(
            lista.copy(
                status = StatusLista.FINALIZADA,
                dataFinalizacao = LocalDateTime.now(),
                totalGasto = totalGasto
            )
        )
    }
}
