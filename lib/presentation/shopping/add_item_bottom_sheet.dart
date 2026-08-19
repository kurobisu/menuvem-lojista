import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/insumo.dart';
import '../components/formatters.dart';
import 'shopping_list_controller.dart';

/// Bottom sheet para adicionar um item à lista: busca de insumos cadastrados
/// ou adição livre (nome/quantidade/unidade/preço digitados).
class AddItemBottomSheet extends ConsumerStatefulWidget {
  const AddItemBottomSheet({super.key, required this.onAdd});

  final void Function({
    required String nomeItem,
    required double quantidade,
    required String unidade,
    double precoUnitario,
    Insumo? insumo,
  })
  onAdd;

  @override
  ConsumerState<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  Insumo? _selectedInsumo;
  final _nomeController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1');
  final _unidadeController = TextEditingController(text: 'un');
  final _precoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _unidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantidade = parseDecimalPtBr(_quantidadeController.text);
    final isValid =
        (_selectedInsumo != null || _nomeController.text.trim().isNotEmpty) &&
        quantidade != null &&
        quantidade > 0;
    final searchAsync = _selectedInsumo == null
        ? ref.watch(insumoSearchProvider(_nomeController.text))
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Adicionar Item',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedInsumo == null) ...[
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do item ou insumo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _nomeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _nomeController.clear()),
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            if (searchAsync != null)
              searchAsync.maybeWhen(
                data: (results) => results.isEmpty
                    ? const SizedBox.shrink()
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView(
                          shrinkWrap: true,
                          children: results
                              .map(
                                (insumo) => ListTile(
                                  leading: const Icon(
                                    Icons.shopping_cart_outlined,
                                  ),
                                  title: Text(insumo.nome),
                                  subtitle: Text(
                                    '${insumo.unidadeCompra} · R\$ ${formatarMoeda(insumo.custoAtual)}',
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedInsumo = insumo;
                                      _nomeController.text = insumo.nome;
                                      _unidadeController.text =
                                          insumo.unidadeCompra;
                                      _precoController.text =
                                          insumo.custoAtual > 0
                                          ? formatarMoeda(insumo.custoAtual)
                                          : '';
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
          ] else
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(_selectedInsumo!.nome),
                subtitle: Text(
                  'Insumo cadastrado · ${_selectedInsumo!.unidadeCompra}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedInsumo = null;
                    _nomeController.clear();
                    _precoController.clear();
                  }),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantidadeController,
                  decoration: const InputDecoration(labelText: 'Qtd'),
                  inputFormatters: [decimalPtBrInputFormatter],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selectedInsumo == null
                    ? TextField(
                        controller: _unidadeController,
                        decoration: const InputDecoration(labelText: 'Unidade'),
                      )
                    : InputDecorator(
                        decoration: const InputDecoration(labelText: 'Unidade'),
                        child: Text(_selectedInsumo!.unidadeCompra),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _precoController,
                  inputFormatters: const [MoedaInputFormatter()],
                  decoration: const InputDecoration(
                    prefixText: 'R\$ ',
                    labelText: 'Preço',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isValid
                ? () {
                    final preco =
                        parseMoedaPtBr(_precoController.text) ?? 0.0;
                    widget.onAdd(
                      nomeItem: _selectedInsumo?.nome ?? _nomeController.text,
                      quantidade: quantidade,
                      unidade:
                          _selectedInsumo?.unidadeCompra ??
                          _unidadeController.text,
                      precoUnitario: preco,
                      insumo: _selectedInsumo,
                    );
                    Navigator.of(context).pop();
                  }
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar à lista'),
          ),
        ],
      ),
    );
  }
}
