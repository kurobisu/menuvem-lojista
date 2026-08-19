import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/componente_repository.dart';
import '../data/contas_salvas_repository.dart';
import '../data/historico_preco_repository.dart';
import '../data/insumo_repository.dart';
import '../data/lista_compras_repository.dart';
import '../data/produto_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Contas do login rápido. Não guarda dados do usuário logado, então fica
/// de fora da invalidação do [sessionResetProvider].
final contasSalvasRepositoryProvider = Provider<ContasSalvasRepository>((ref) {
  return ContasSalvasRepository();
});

final insumoRepositoryProvider = Provider<InsumoRepository>((ref) {
  return InsumoRepository(ref.watch(supabaseClientProvider));
});

final produtoRepositoryProvider = Provider<ProdutoRepository>((ref) {
  return ProdutoRepository(ref.watch(supabaseClientProvider));
});

final componenteRepositoryProvider = Provider<ComponenteRepository>((ref) {
  return ComponenteRepository(ref.watch(supabaseClientProvider));
});

final listaComprasRepositoryProvider = Provider<ListaComprasRepository>((ref) {
  return ListaComprasRepository(ref.watch(supabaseClientProvider));
});

final historicoPrecoRepositoryProvider = Provider<HistoricoPrecoRepository>((
  ref,
) {
  return HistoricoPrecoRepository(ref.watch(supabaseClientProvider));
});
