import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_providers.dart';

/// Estado da sessão: emite a cada mudança (signedIn, signedOut, sessão
/// restaurada do storage etc). O router usa isto para decidir entre
/// LoginScreen e o app autenticado.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Lê a sessão atual diretamente do SDK (síncrono), em vez de depender do
/// valor em cache do [authStateProvider]. O SDK atualiza `currentSession`
/// antes de emitir o evento em `onAuthStateChange` — se o router lesse o
/// StreamProvider aqui, haveria uma corrida entre a própria subscription do
/// StreamProvider e a do `refreshListenable` do go_router (ambas ouvindo o
/// mesmo stream): o redirect podia rodar antes do Riverpod atualizar o
/// valor em cache, deixando o usuário preso na tela de login mesmo após um
/// login bem-sucedido.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).currentSession != null;
});
