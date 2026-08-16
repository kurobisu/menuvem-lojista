package br.com.menuvem.lojista.domain.model

/**
 * Tipo de um [Componente] (bloco reutilizável de ficha técnica).
 * Ex.: "Pizza - Massa Grande 35cm" é MASSA; "Pizza Sabor - Calabresa" é SABOR.
 * O tipo ajuda a organizar a biblioteca de componentes e a sugerir divisões
 * (componentes de sabor são divididos por nº de sabores na mesma massa).
 */
enum class TipoComponente {
    MASSA,
    SABOR,
    EMBALAGEM,
    OUTRO
}