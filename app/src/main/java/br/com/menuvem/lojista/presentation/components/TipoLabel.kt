package br.com.menuvem.lojista.presentation.components

import br.com.menuvem.lojista.domain.model.TipoComponente

/** Rótulo pt-BR de um tipo de componente. */
fun formatarTipo(tipo: TipoComponente): String = when (tipo) {
    TipoComponente.MASSA -> "Massa"
    TipoComponente.SABOR -> "Sabor"
    TipoComponente.EMBALAGEM -> "Embalagem"
    TipoComponente.OUTRO -> "Outro"
}