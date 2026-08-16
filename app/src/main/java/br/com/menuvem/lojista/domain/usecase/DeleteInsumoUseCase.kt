package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Exclui um insumo, desde que ele não seja usado em nenhuma ficha técnica
 * (a FK é RESTRICT — esta verificação evita o crash e devolve mensagem amigável).
 *
 * @return mensagem de erro se o insumo estiver em uso; null se excluiu.
 */
class DeleteInsumoUseCase @Inject constructor(
    private val insumoRepository: InsumoRepository,
    private val produtoRepository: ProdutoRepository
) {
    suspend operator fun invoke(insumo: Insumo): String? {
        val usos = produtoRepository.getItensFichaByInsumo(insumo.id)
        return if (usos.isNotEmpty()) {
            "Usado em ${usos.size} ficha(s) técnica(s) — remova-o das fichas antes de excluir"
        } else {
            insumoRepository.deleteInsumo(insumo)
            null
        }
    }
}
