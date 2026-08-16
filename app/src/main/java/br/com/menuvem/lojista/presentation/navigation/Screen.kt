package br.com.menuvem.lojista.presentation.navigation

/** Rotas da aplicação. */
sealed class Screen(val route: String) {
    data object Home : Screen("home")
    data object ShoppingLists : Screen("shopping_lists")
    data object ShoppingList : Screen("shopping_list/{listaId}") {
        fun createRoute(listaId: Long) = "shopping_list/$listaId"
    }
    data object PriceHistory : Screen("price_history")
    data object InsumoHistory : Screen("insumo_history/{insumoId}") {
        fun createRoute(insumoId: Long) = "insumo_history/$insumoId"
    }
    data object Produtos : Screen("produtos")
    data object ProdutoDetail : Screen("produto/{produtoId}") {
        fun createRoute(produtoId: Long) = "produto/$produtoId"
    }
    data object Componentes : Screen("componentes")
    data object ComponenteDetail : Screen("componente/{componenteId}") {
        fun createRoute(componenteId: Long) = "componente/$componenteId"
    }
    data object Insumos : Screen("insumos")
}
