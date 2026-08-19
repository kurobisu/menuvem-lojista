import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/item_componente.dart';
import '../../domain/model/item_componente_com_insumo.dart';
import '../../domain/model/tamanho_componente.dart';
import '../../domain/usecase/componente_usecases.dart' as usecase;
import '../../domain/usecase/cost_engine.dart';
import '../../providers/repository_providers.dart';
import 'componentes_controller.dart' show componentesLibraryProvider;

/// Tamanhos de um componente, na ordem de exibição.
final tamanhosComponenteProvider =
    StreamProvider.family<List<TamanhoComponente>, int>((ref, componenteId) {
      return ref
          .watch(componenteRepositoryProvider)
          .getTamanhosByComponente(componenteId);
    });

/// Itens (insumos) de um **tamanho** de componente.
final itensTamanhoProvider =
    StreamProvider.family<List<ItemComponenteComInsumo>, int>((
      ref,
      tamanhoComponenteId,
    ) {
      return getItensTamanho(
        componenteRepository: ref.watch(componenteRepositoryProvider),
        insumoRepository: ref.watch(insumoRepositoryProvider),
        tamanhoComponenteId: tamanhoComponenteId,
      );
    });

class ComponenteDetailActions {
  ComponenteDetailActions(this.ref, this.componenteId);
  final Ref ref;
  final int componenteId;

  Future<void> updateComponente(
    String nome,
    String? tipoNome,
    String? emoji,
  ) async {
    final repo = ref.read(componenteRepositoryProvider);
    final c = await repo.getComponenteById(componenteId);
    if (c == null) return;
    final tipoId = await usecase.resolveTipoComponenteId(repo, tipoNome);
    await repo.updateComponente(
      c.copyWith(
        nome: nome,
        tipoComponenteId: tipoId,
        clearTipoComponenteId: tipoId == null,
        emoji: emoji,
        clearEmoji: emoji == null,
      ),
    );
  }

  Future<void> deleteComponente() async {
    final componente = await ref
        .read(componenteRepositoryProvider)
        .getComponenteById(componenteId);
    if (componente == null) return;
    await ref.read(componenteRepositoryProvider).deleteComponente(componente);
  }

  Future<int> duplicarComponente() async {
    final repo = ref.read(componenteRepositoryProvider);
    final componente = await repo.getComponenteById(componenteId);
    if (componente == null) return componenteId;
    final ordemNova =
        ref.read(componentesLibraryProvider).asData?.value.length ?? 0;
    return usecase.duplicarComponente(repo, componente, ordem: ordemNova);
  }

  // ── Tamanhos ─────────────────────────────────────────────────────────

  Future<int> addTamanho({
    required String nome,
    int? copiarItensDoTamanhoId,
  }) async {
    final repo = ref.read(componenteRepositoryProvider);
    final ordemNova =
        ref.read(tamanhosComponenteProvider(componenteId)).asData?.value.length ??
        0;
    return usecase.criarTamanho(
      repo,
      componenteId: componenteId,
      nome: nome,
      ordem: ordemNova,
      copiarItensDoTamanhoId: copiarItensDoTamanhoId,
    );
  }

  Future<void> updateTamanho(TamanhoComponente tamanho, {required String nome}) {
    return usecase.saveTamanhoComponente(
      ref.read(componenteRepositoryProvider),
      tamanho.copyWith(nome: nome),
    );
  }

  Future<void> deleteTamanho(TamanhoComponente tamanho) {
    return ref.read(componenteRepositoryProvider).deleteTamanho(tamanho);
  }

  // ── Itens de um tamanho ──────────────────────────────────────────────

  Future<void> addItem(
    int tamanhoComponenteId,
    int insumoId,
    double quantidade,
    double perda,
  ) {
    return usecase.saveItemComponente(
      ref.read(componenteRepositoryProvider),
      ItemComponente(
        tamanhoComponenteId: tamanhoComponenteId,
        insumoId: insumoId,
        quantidade: quantidade,
        perdaPercentual: perda,
      ),
    );
  }

  Future<void> updateItem(
    ItemComponente item,
    double quantidade,
    double perda,
  ) {
    return usecase.saveItemComponente(
      ref.read(componenteRepositoryProvider),
      item.copyWith(quantidade: quantidade, perdaPercentual: perda),
    );
  }

  Future<void> removeItem(ItemComponente item) {
    return ref.read(componenteRepositoryProvider).deleteItemComponente(item);
  }
}

final componenteDetailActionsProvider =
    Provider.family<ComponenteDetailActions, int>((ref, componenteId) {
      return ComponenteDetailActions(ref, componenteId);
    });
