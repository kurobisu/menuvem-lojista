import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/categoria_insumo.dart';
import '../../domain/model/insumo.dart';
import '../../domain/usecase/insumo_usecases.dart' as usecase;
import '../../providers/repository_providers.dart';

final insumosStreamProvider = StreamProvider<List<Insumo>>((ref) {
  return ref.watch(insumoRepositoryProvider).getAllInsumos();
});

class InsumosUiState {
  final CategoriaInsumo? filtroCategoria;
  final bool showFormDialog;
  final Insumo? insumoEmEdicao;
  final Insumo? insumoParaExcluir;
  final String? error;

  const InsumosUiState({
    this.filtroCategoria,
    this.showFormDialog = false,
    this.insumoEmEdicao,
    this.insumoParaExcluir,
    this.error,
  });

  InsumosUiState copyWith({
    CategoriaInsumo? filtroCategoria,
    bool clearFiltro = false,
    bool? showFormDialog,
    Insumo? insumoEmEdicao,
    bool clearInsumoEmEdicao = false,
    Insumo? insumoParaExcluir,
    bool clearInsumoParaExcluir = false,
    String? error,
    bool clearError = false,
  }) {
    return InsumosUiState(
      filtroCategoria: clearFiltro
          ? null
          : (filtroCategoria ?? this.filtroCategoria),
      showFormDialog: showFormDialog ?? this.showFormDialog,
      insumoEmEdicao: clearInsumoEmEdicao
          ? null
          : (insumoEmEdicao ?? this.insumoEmEdicao),
      insumoParaExcluir: clearInsumoParaExcluir
          ? null
          : (insumoParaExcluir ?? this.insumoParaExcluir),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InsumosController extends Notifier<InsumosUiState> {
  @override
  InsumosUiState build() => const InsumosUiState();

  void onFiltroChange(CategoriaInsumo? categoria) {
    state = state.copyWith(
      filtroCategoria: categoria,
      clearFiltro: categoria == null,
    );
  }

  void onShowForm([Insumo? insumo]) {
    state = state.copyWith(
      showFormDialog: true,
      insumoEmEdicao: insumo,
      clearInsumoEmEdicao: insumo == null,
    );
  }

  void onHideForm() {
    state = state.copyWith(showFormDialog: false, clearInsumoEmEdicao: true);
  }

  Future<void> save({
    required String nome,
    required CategoriaInsumo categoria,
    required String unidadeCompra,
    required String unidadeUso,
    required double fatorConversao,
    required double custoAtual,
    String? emoji,
  }) async {
    final emEdicao = state.insumoEmEdicao;
    final base =
        emEdicao ??
        Insumo(
          nome: nome,
          unidadeCompra: unidadeCompra,
          unidadeUso: unidadeUso,
          fatorConversao: fatorConversao,
        );
    await usecase.saveInsumo(
      ref.read(insumoRepositoryProvider),
      base.copyWith(
        nome: nome,
        categoria: categoria,
        unidadeCompra: unidadeCompra,
        unidadeUso: unidadeUso,
        fatorConversao: fatorConversao,
        custoAtual: custoAtual,
        emoji: emoji,
        clearEmoji: emoji == null,
      ),
    );
    onHideForm();
  }

  void onShowDeleteConfirm(Insumo insumo) {
    state = state.copyWith(insumoParaExcluir: insumo);
  }

  void onHideDeleteConfirm() {
    state = state.copyWith(clearInsumoParaExcluir: true);
  }

  Future<void> delete() async {
    final insumo = state.insumoParaExcluir;
    if (insumo == null) return;
    final erro = await usecase.deleteInsumo(
      insumoRepository: ref.read(insumoRepositoryProvider),
      produtoRepository: ref.read(produtoRepositoryProvider),
      componenteRepository: ref.read(componenteRepositoryProvider),
      insumo: insumo,
    );
    state = state.copyWith(
      clearInsumoParaExcluir: true,
      error: erro,
      clearError: erro == null,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final insumosControllerProvider =
    NotifierProvider<InsumosController, InsumosUiState>(InsumosController.new);
