import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/item_componente.dart';
import '../../domain/usecase/componente_usecases.dart' as usecase;
import '../../providers/repository_providers.dart';

class ComponenteDetailActions {
  ComponenteDetailActions(this.ref, this.componenteId);
  final Ref ref;
  final int componenteId;

  Future<void> updateComponente(String nome, String? tipoNome, String? emoji) async {
    final repo = ref.read(componenteRepositoryProvider);
    final c = await repo.getComponenteById(componenteId);
    if (c == null) return;
    final tipoId = await usecase.resolveTipoComponenteId(repo, tipoNome);
    await repo.updateComponente(c.copyWith(
      nome: nome,
      tipoComponenteId: tipoId,
      clearTipoComponenteId: tipoId == null,
      emoji: emoji,
      clearEmoji: emoji == null,
    ));
  }

  Future<void> deleteComponente() async {
    final componente =
        await ref.read(componenteRepositoryProvider).getComponenteById(componenteId);
    if (componente == null) return;
    await ref.read(componenteRepositoryProvider).deleteComponente(componente);
  }

  Future<void> addItem(int insumoId, double quantidade, double perda) {
    return usecase.saveItemComponente(
      ref.read(componenteRepositoryProvider),
      ItemComponente(
        componenteId: componenteId,
        insumoId: insumoId,
        quantidade: quantidade,
        perdaPercentual: perda,
      ),
    );
  }

  Future<void> updateItem(ItemComponente item, double quantidade, double perda) {
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
