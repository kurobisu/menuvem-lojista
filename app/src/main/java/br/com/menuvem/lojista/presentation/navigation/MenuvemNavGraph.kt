package br.com.menuvem.lojista.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import br.com.menuvem.lojista.presentation.history.InsumoHistoryScreen
import br.com.menuvem.lojista.presentation.history.PriceHistoryScreen
import br.com.menuvem.lojista.presentation.home.HomeScreen
import br.com.menuvem.lojista.presentation.insumos.InsumosScreen
import br.com.menuvem.lojista.presentation.products.ProdutoDetailScreen
import br.com.menuvem.lojista.presentation.products.ProdutosScreen
import br.com.menuvem.lojista.presentation.shopping.ShoppingListScreen
import br.com.menuvem.lojista.presentation.shopping.ShoppingListsScreen

@Composable
fun MenuvemNavGraph(navController: NavHostController) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToListas = { navController.navigate(Screen.ShoppingLists.route) },
                onNavigateToLista = { listaId ->
                    navController.navigate(Screen.ShoppingList.createRoute(listaId))
                },
                onNavigateToHistorico = { navController.navigate(Screen.PriceHistory.route) },
                onNavigateToInsumoHistory = { insumoId ->
                    navController.navigate(Screen.InsumoHistory.createRoute(insumoId))
                },
                onNavigateToProdutos = { navController.navigate(Screen.Produtos.route) },
                onNavigateToProduto = { produtoId ->
                    navController.navigate(Screen.ProdutoDetail.createRoute(produtoId))
                },
                onNavigateToInsumos = { navController.navigate(Screen.Insumos.route) }
            )
        }

        composable(Screen.ShoppingLists.route) {
            ShoppingListsScreen(
                onNavigateToLista = { listaId ->
                    navController.navigate(Screen.ShoppingList.createRoute(listaId))
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.ShoppingList.route,
            arguments = listOf(navArgument("listaId") { type = NavType.LongType })
        ) { backStack ->
            val listaId = backStack.arguments?.getLong("listaId") ?: return@composable
            ShoppingListScreen(
                listaId = listaId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.PriceHistory.route) {
            PriceHistoryScreen(
                onNavigateToInsumo = { insumoId ->
                    navController.navigate(Screen.InsumoHistory.createRoute(insumoId))
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.InsumoHistory.route,
            arguments = listOf(navArgument("insumoId") { type = NavType.LongType })
        ) { backStack ->
            val insumoId = backStack.arguments?.getLong("insumoId") ?: return@composable
            InsumoHistoryScreen(
                insumoId = insumoId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Produtos.route) {
            ProdutosScreen(
                onNavigateToProduto = { produtoId ->
                    navController.navigate(Screen.ProdutoDetail.createRoute(produtoId))
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.ProdutoDetail.route,
            arguments = listOf(navArgument("produtoId") { type = NavType.LongType })
        ) {
            ProdutoDetailScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Insumos.route) {
            InsumosScreen(
                onBack = { navController.popBackStack() }
            )
        }
    }
}
