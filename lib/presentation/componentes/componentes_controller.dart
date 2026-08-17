import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/componente.dart';
import '../../domain/model/componente_com_custo.dart';
import '../../domain/model/tipo_componente.dart';
import '../../domain/usecase/componente_usecases.dart' as usecase;
import '../../providers/repository_providers.dart';

export '../products/produto_detail_controller.dart' show componentesLibraryProvider;

class ComponentesUiState {
  final TipoComponente? filtroTipo;
  final bool showFormDialog;
  final Componente? componenteEmEdicao;
  final ComponenteComCusto? componenteParaExcluir;
  final String? error;

  const ComponentesUiState({
    this.filtroTipo,
    this.showFormDialog = false,
    this.componenteEmEdicao,
    this.componenteParaExcluir,
    this.error,
  });

  ComponentesUiState copyWith({
    TipoComponente? filtroTipo,
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
      filtroTipo: clearFiltro ? null : (filtroTipo ?? this.filtroTipo),
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

  void onFiltroChange(TipoComponente? tipo) {
    state = state.copyWith(filtroTipo: tipo, clearFiltro: tipo == null);
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

  Future<void> save(String nome, TipoComponente tipo) async {
    final emEdicao = state.componenteEmEdicao;
    final base = emEdicao ?? Componente(nome: nome, tipo: tipo);
    await usecase.saveComponente(
      ref.read(componenteRepositoryProvider),
      base.copyWith(nome: nome, tipo: tipo),
    );
    onHideForm();
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
