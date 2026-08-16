package br.com.menuvem.lojista.domain.usecase

import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.domain.repository.ComponenteRepository
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import javax.inject.Inject

/**
 * Exclui um insumo, desde que ele não seja usado em nenhuma ficha técnica nem
 * em nenhum componente (FK é RESTRICT — esta verificação evita o crash e
 * devolve mensagem amigável).
 *
 * @return mensagem de erro se o insumo estiver em uso; null se excluiu.
 */
class DeleteInsumoUseCase @Inject constructor(
    private val insumoRepository: InsumoRepository,
    private val produtoRepository: ProdutoRepository,
    private val componenteRepository: ComponenteRepository
) {
    suspend operator fun invoke(insumo: Insumo): String? {
        val usosFicha = produtoRepository.getItensFichaByInsumo(insumo.id)
        if (usosFicha.isNotEmpty()) {
            return "Usado em ${usosFicha.size} ficha(s) técnica(s) — remova-o das fichas antes de excluir"
        }
        val usosComponente = componenteRepository.getItensByInsumo(insumo.id)
        if (usosComponente.isNotEmpty()) {
            return "Usado em ${usosComponente.size} componente(s) — remova-o antes de excluir"
        }
        insumoRepository.deleteInsumo(insumo)
        return null
    }
}