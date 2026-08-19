import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/tipo_componente.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import 'componentes_controller.dart' show tiposComponenteProvider;

/// Tela dedicada pra reordenar os tipos de componente: segurar e arrastar,
/// nada é gravado até tocar em Salvar (que só aparece quando a ordem muda).
class TiposReorderScreen extends ConsumerStatefulWidget {
  const TiposReorderScreen({super.key});

  @override
  ConsumerState<TiposReorderScreen> createState() => _TiposReorderScreenState();
}

class _TiposReorderScreenState extends ConsumerState<TiposReorderScreen> {
  List<TipoComponente>? _local;
  bool _hasChanges = false;
  bool _isSaving = false;

  Future<void> _salvar() async {
    final local = _local;
    if (local == null || !_hasChanges) return;
    setState(() => _isSaving = true);
    final ordemPorId = {
      for (var i = 0; i < local.length; i++) local[i].id: i,
    };
    await ref.read(componenteRepositoryProvider).updateOrdensTipos(ordemPorId);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasChanges = false;
      _local = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ordem dos tipos salva')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(tiposComponenteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reordenar tipos'),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purplePrimary,
                  foregroundColor: Colors.white,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Salvar'),
              ),
            ),
        ],
      ),
      body: tiposAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purplePrimary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (tipos) {
          if (!_hasChanges) _local = List.of(tipos);
          final lista = _local!;

          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum tipo cadastrado ainda. Crie um ao adicionar um componente.'),
              ),
            );
          }

          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: lista.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final novaLista = List.of(lista);
                final item = novaLista.removeAt(oldIndex);
                novaLista.insert(newIndex, item);
                _local = novaLista;
                _hasChanges = true;
              });
            },
            itemBuilder: (context, index) {
              final tipo = lista[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(tipo.id),
                index: index,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_indicator, color: onSurfaceVariantLight),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(tipo.nome, style: Theme.of(context).textTheme.titleSmall),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
