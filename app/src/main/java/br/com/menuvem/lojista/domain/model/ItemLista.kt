package br.com.menuvem.lojista.domain.model

/**
 * Modelo de domínio: Item dentro de uma lista de compras.
 *
 * @param insumoId  null se o item não estiver vinculado a um insumo cadastrado.
 * @param nomeItem  Nome exibido (pode ser o nome do insumo ou digitado livremente).
 * @param quantidade Quantidade prevista na lista.
 * @param unidade   Unidade de medida do item nesta lista.
 * @param precoUnitario Preço por unidade registrado na compra (preenchido ao marcar).
 * @param comprado  true quando o usuário marcou como comprado.
 */
data class ItemLista(
    val id: Long = 0,
    val listaComprasId: Long,
    val insumoId: Long? = null,
    val nomeItem: String,
    val quantidade: Double,
    val unidade: String,
    val precoUnitario: Double = 0.0,
    val comprado: Boolean = false
) {
    val precoTotal: Double
        get() = quantidade * precoUnitario

    val estaVinculado: Boolean
        get() = insumoId != null
}
