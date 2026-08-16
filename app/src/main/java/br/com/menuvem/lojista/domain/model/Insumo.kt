package br.com.menuvem.lojista.domain.model

import java.time.LocalDateTime

/**
 * Modelo de domínio: Insumo (ingrediente/matéria-prima).
 *
 * @param unidadeCompra  Ex: "kg", "cx", "fardo"
 * @param unidadeUso     Ex: "g", "un"
 * @param fatorConversao Quantas unidades de uso existem em 1 unidade de compra.
 *                       Ex: 1 kg = 1000 g → fatorConversao = 1000.0
 * @param custoAtual     Preço da última compra, por unidade de COMPRA.
 * @param categoria      INSUMO (padrão) ou EMBALAGEM (caixa, copo, sacola...).
 */
data class Insumo(
    val id: Long = 0,
    val nome: String,
    val unidadeCompra: String,
    val unidadeUso: String,
    val fatorConversao: Double,       // 1 unidadeCompra = fatorConversao * unidadeUso
    val custoAtual: Double = 0.0,     // R$ por unidadeCompra
    val dataCriacao: LocalDateTime = LocalDateTime.now(),
    val categoria: CategoriaInsumo = CategoriaInsumo.INSUMO
) {
    /** Custo por unidade de uso (calculado). */
    val custoPorUnidadeUso: Double
        get() = if (fatorConversao > 0) custoAtual / fatorConversao else 0.0
}
