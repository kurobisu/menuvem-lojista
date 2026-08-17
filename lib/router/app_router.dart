import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/componentes/componente_detail_screen.dart';
import '../presentation/componentes/componentes_screen.dart';
import '../presentation/history/insumo_history_screen.dart';
import '../presentation/history/price_history_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/insumos/insumos_screen.dart';
import '../presentation/products/produto_detail_screen.dart';
import '../presentation/products/produtos_screen.dart';
import '../presentation/shopping/shopping_list_screen.dart';
import '../presentation/shopping/shopping_lists_screen.dart';
import '../providers/auth_providers.dart' show isAuthenticatedProvider;
import '../providers/repository_providers.dart' show authRepositoryProvider;

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authenticated = ref.read(isAuthenticatedProvider);
      final onLogin = state.matchedLocation == '/login';
      if (!authenticated && !onLogin) return '/login';
      if (authenticated && onLogin) return '/home';
      return null;
    },
    refreshListenable: _GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges,
    ),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/shopping-lists',
        builder: (context, state) => const ShoppingListsScreen(),
      ),
      GoRoute(
        path: '/shopping-lists/:listaId',
        builder: (context, state) => ShoppingListScreen(
          listaId: int.parse(state.pathParameters['listaId']!),
        ),
      ),
      GoRoute(
        path: '/price-history',
        builder: (context, state) => const PriceHistoryScreen(),
      ),
      GoRoute(
        path: '/price-history/:insumoId',
        builder: (context, state) => InsumoHistoryScreen(
          insumoId: int.parse(state.pathParameters['insumoId']!),
        ),
      ),
      GoRoute(
        path: '/produtos',
        builder: (context, state) => const ProdutosScreen(),
      ),
      GoRoute(
        path: '/produtos/:produtoId',
        builder: (context, state) => ProdutoDetailScreen(
          produtoId: int.parse(state.pathParameters['produtoId']!),
        ),
      ),
      GoRoute(
        path: '/componentes',
        builder: (context, state) => const ComponentesScreen(),
      ),
      GoRoute(
        path: '/componentes/:componenteId',
        builder: (context, state) => ComponenteDetailScreen(
          componenteId: int.parse(state.pathParameters['componenteId']!),
        ),
      ),
      GoRoute(
        path: '/insumos',
        builder: (context, state) => const InsumosScreen(),
      ),
    ],
  );
});
