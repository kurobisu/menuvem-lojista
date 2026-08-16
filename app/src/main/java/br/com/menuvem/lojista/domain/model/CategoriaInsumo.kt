package br.com.menuvem.lojista.domain.model

/**
 * Categoria de um Insumo. Embalagens são insumos categorizados — reutilizam
 * listas de compras, histórico de preços e conversão de unidades, e entram
 * na ficha técnica como itens normais.
 */
enum class CategoriaInsumo {
    INSUMO,
    EMBALAGEM
}
