import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/componente.dart';
import '../../domain/model/componente_com_custo.dart';
import '../../domain/model/tipo_componente.dart';
import '../../domain/usecase/componente_usecases.dart' as usecase;
import '../../providers/repository_providers.dart';
import '../products/produto_detail_controller.dart' show componentesLibraryProvider;

export '../products/produto_detail_controller.dart' show componentesLibraryProvider;

/// Tipos de componente já cadastrados pelo usuário (usados como sugestão de
/// autocompletar ao criar/editar um componente).
final tiposComponenteProvider = StreamProvider<List<TipoComponente>>((ref) {
  return ref.watch(componenteRepositoryProvider).getAllTipos();
});

class ComponentesUiState {
  final int? filtroTipoId;
  final bool showFormDialog;
  final Componente? componenteEmEdicao;
  final ComponenteComCusto? componenteParaExcluir;
  final String? error;

  const ComponentesUiState({
    this.filtroTipoId,
    this.showFormDialog = false,
    this.componenteEmEdicao,
    this.componenteParaExcluir,
    this.error,
  });

  ComponentesUiState copyWith({
    int? filtroTipoId,
    bool clearFiltro = false,
    bool? showFormDialog,
    Componente? componenteEmEdicao,
    bool clearComponenteEmEdicao = false,
    ComponenteComCusto? componenteParaExcluir,
    bool clearComponenteParaExcluir = false,
    String? error,
    bool clearError = false,
  }) {
    return ComponentesUiState(
      filtroTipoId: clearFiltro ? null : (filtroTipoId ?? this.filtroTipoId),
      showFormDialog: showFormDialog ?? this.showFormDialog,
      componenteEmEdicao:
          clearComponenteEmEdicao ? null : (componenteEmEdicao ?? this.componenteEmEdicao),
      componenteParaExcluir: clearComponenteParaExcluir
          ? null
          : (componenteParaExcluir ?? this.componenteParaExcluir),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ComponentesController extends Notifier<ComponentesUiState> {
  @override
  ComponentesUiState build() => const ComponentesUiState();

  void onFiltroChange(int? tipoId) {
    state = state.copyWith(filtroTipoId: tipoId, clearFiltro: tipoId == null);
  }

  void onShowForm([Componente? componente]) {
    state = state.copyWith(
      showFormDialog: true,
      componenteEmEdicao: componente,
      clearComponenteEmEdicao: componente == null,
    );
  }

  void onHideForm() {
    state = state.copyWith(showFormDialog: false, clearComponenteEmEdicao: true);
  }

  Future<void> save(String nome, String? tipoNome) async {
    final repo = ref.read(componenteRepositoryProvider);
    final tipoId = await usecase.resolveTipoComponenteId(repo, tipoNome);
    final emEdicao = state.componenteEmEdicao;
    final ordemNova = ref.read(componentesLibraryProvider).asData?.value.length ?? 0;
    final base = emEdicao ?? Componente(nome: nome, ordem: ordemNova);
    await usecase.saveComponente(
      repo,
      base.copyWith(
        nome: nome,
        tipoComponenteId: tipoId,
        clearTipoComponenteId: tipoId == null,
      ),
    );
    onHideForm();
  }

  /// Grava a nova ordem dos componentes (arrastar-e-soltar com o filtro
  /// "Todos" ativo).
  Future<void> salvarOrdemComponentes(List<ComponenteComCusto> novaOrdem) {
    final ordemPorId = {
      for (var i = 0; i < novaOrdem.length; i++) novaOrdem[i].componente.id: i,
    };
    return ref.read(componenteRepositoryProvider).updateOrdensComponentes(ordemPorId);
  }

  /// Exclui um tipo de componente. Os componentes desse tipo ficam sem tipo
  /// (FK `on delete set null`) — não são excluídos.
  Future<void> deleteTipo(int tipoId) async {
    await ref.read(componenteRepositoryProvider).deleteTipo(tipoId);
    if (state.filtroTipoId == tipoId) {
      state = state.copyWith(clearFiltro: true);
    }
  }

  void onShowDeleteConfirm(ComponenteComCusto item) {
    state = state.copyWith(componenteParaExcluir: item);
  }

  void onHideDeleteConfirm() {
    state = state.copyWith(clearComponenteParaExcluir: true);
  }

  Future<void> delete() async {
    final item = state.componenteParaExcluir;
    if (item == null) return;
    await ref.read(componenteRepositoryProvider).deleteComponente(item.componente);
    state = state.copyWith(clearComponenteParaExcluir: true);
  }
}

final componentesControllerProvider =
    NotifierProvider<ComponentesController, ComponentesUiState>(ComponentesController.new);
