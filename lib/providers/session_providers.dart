import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// Descarta os dados em cache quando o usuário logado muda.
///
/// Sem isto, sair de uma conta e entrar em outra deixa na tela os dados da
/// conta anterior: os `StreamProvider`s de dados continuam vivos enquanto
/// houver quem os observe, então o Riverpod devolve o último valor em cache —
/// que pertence ao usuário antigo — até que o stream do Supabase emita de
/// novo. Com RLS, o usuário novo pode simplesmente não ter dados, e nesse caso
/// nada nunca chega para substituir o que está na tela.
///
/// A correção é invalidar os repositórios de dados na troca de usuário. Como
/// todo provider de dados observa (`watch`) um destes repositórios, invalidá-los
/// derruba em cascata todo o cache derivado e recria os streams já no contexto
/// do usuário novo.
///
/// Note que isto **não** é o mesmo tipo de armadilha do antigo
/// `isAuthenticatedProvider` (ver "Gotchas" no AGENTS.md): aqui não há estado
/// derivado sendo cacheado e lido depois — é só um listener que dispara um
/// efeito colateral quando o usuário troca.
///
/// `authRepositoryProvider` e `supabaseClientProvider` são deixados de fora de
/// propósito: o router observa o de auth, e invalidá-lo recriaria o `GoRouter`
/// inteiro no meio de uma transição de rota.
final sessionResetProvider = Provider<void>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  var usuarioAtual = authRepository.currentSession?.user.id;

  final subscription = authRepository.authStateChanges.listen((estado) {
    final novoUsuario = estado.session?.user.id;
    if (novoUsuario == usuarioAtual) return;
    usuarioAtual = novoUsuario;

    ref.invalidate(insumoRepositoryProvider);
    ref.invalidate(produtoRepositoryProvider);
    ref.invalidate(componenteRepositoryProvider);
    ref.invalidate(listaComprasRepositoryProvider);
    ref.invalidate(historicoPrecoRepositoryProvider);
  });

  ref.onDispose(subscription.cancel);
});
