import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'providers/session_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: MenuvemLojistaApp()));
}

class MenuvemLojistaApp extends ConsumerWidget {
  const MenuvemLojistaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantém vivos os listeners de sessão: limpar o cache ao trocar de conta
    // e acompanhar a rotação do refresh token das contas salvas.
    ref.watch(sessionResetProvider);
    ref.watch(tokenSyncProvider);
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Menuvem Lojista',
      debugShowCheckedModeBanner: false,
      theme: menuvemLojistaTheme(),
      routerConfig: router,
    );
  }
}
