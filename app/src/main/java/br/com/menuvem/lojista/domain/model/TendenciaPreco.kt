package br.com.menuvem.lojista.domain.model

/** Tendência de preço de um insumo com base nas últimas 3 compras. */
enum class TendenciaPreco {
    ALTA,     // Preço subiu
    ESTAVEL,  // Preço manteve-se próximo
    QUEDA;    // Preço caiu

    companion object {
        /**
         * Calcula a tendência com base em uma lista de preços históricos
         * (do mais antigo para o mais recente).
         * Usa variação percentual entre o mais recente e o mais antigo da janela.
         */
        fun calcular(precos: List<Double>): TendenciaPreco {
            if (precos.size < 2) return ESTAVEL
            val janela = precos.takeLast(3)
            val primeiro = janela.first()
            val ultimo = janela.last()
            if (primeiro == 0.0) return ESTAVEL
            val variacao = (ultimo - primeiro) / primeiro
            return when {
                variacao > 0.02  -> ALTA     // > +2%
                variacao < -0.02 -> QUEDA    // < -2%
                else             -> ESTAVEL
            }
        }
    }
}
