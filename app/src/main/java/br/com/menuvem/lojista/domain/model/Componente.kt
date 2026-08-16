package br.com.menuvem.lojista.domain.model

import java.time.LocalDateTime

/**
 * Componente: bloco reutilizável de ficha técnica.
 *
 * Um componente é um "template" de itens (insumos + quantidades) que pode ser
 * reaproveitado em vários produtos — ex.: "Pizza - Massa Grande 35cm" (base de
 * massa) e "Pizza Sabor - Calabresa" (recheio). Ao montar um produto, o
 * componente entra com um [ProdutoComponente.multiplicador] (ex.: sabor único =
 * 1; 2 sabores na mesma massa = 0,5; 3 sabores = 1/3).
 *
 * @param tipo Ver [TipoComponente]. Ajuda a organizar e a sugerir divisões.
 */
data class Componente(
    val id: Long = 0,
    val nome: String,
    val tipo: TipoComponente = TipoComponente.OUTRO,
    val dataCriacao: LocalDateTime = LocalDateTime.now()
)