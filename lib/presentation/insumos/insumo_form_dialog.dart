import 'package:flutter/material.dart';

import '../../domain/model/categoria_insumo.dart';
import '../../domain/model/insumo.dart';
import '../../theme/app_theme.dart';
import '../components/formatters.dart';
import '../components/unidades_medida.dart';

typedef InsumoFormConfirm = void Function({
  required String nome,
  required CategoriaInsumo categoria,
  required String unidadeCompra,
  required String unidadeUso,
  required double fatorConversao,
  required double custoAtual,
});

/// Normaliza pro valor canônico do preset (comparação sem diferenciar
/// maiúsculas/minúsculas) ou devolve o valor bruto se não bater com nenhum
/// preset — caso de insumos cadastrados antes da lista fechada existir.
String? _normalizarUnidade(String? valor) {
  if (valor == null || valor.isEmpty) return null;
  for (final u in unidadesMedida) {
    if (u.valor.toLowerCase() == valor.toLowerCase()) return u.valor;
  }
  return valor;
}

List<DropdownMenuItem<String>> _itensUnidade(String? valorAtual) {
  final conhecidos = unidadesMedida.map((u) => u.valor.toLowerCase()).toSet();
  final items = [
    for (final u in unidadesMedida)
      DropdownMenuItem(
        value: u.valor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(u.icone, size: 16),
            const SizedBox(width: 6),
            Text(u.rotulo),
          ],
        ),
      ),
  ];
  if (valorAtual != null && !conhecidos.contains(valorAtual.toLowerCase())) {
    items.insert(
      0,
      DropdownMenuItem(
        value: valorAtual,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconeUnidade(valorAtual), size: 16),
            const SizedBox(width: 6),
            Text(valorAtual),
          ],
        ),
      ),
    );
  }
  return items;
}

/// Folha de criação/edição de insumo da biblioteca: nome, categoria
/// (insumo/embalagem), unidade de compra, unidade de uso, fator de conversão
/// e custo atual (override manual do preço vindo do histórico de compras).
///
/// O botão Salvar fica no cabeçalho fixo (nunca atrás do teclado) — só o
/// conteúdo abaixo rola.
class InsumoFormDialog extends StatefulWidget {
  const InsumoFormDialog({
    super.key,
    this.insumo,
    required this.onConfirm,
  });

  final Insumo? insumo;
  final InsumoFormConfirm onConfirm;

  @override
  State<InsumoFormDialog> createState() => _InsumoFormDialogState();
}

class _InsumoFormDialogState extends State<InsumoFormDialog> {
  late final _nomeController = TextEditingController(text: widget.insumo?.nome ?? '');
  late CategoriaInsumo _categoria = widget.insumo?.categoria ?? CategoriaInsumo.insumo;
  late String? _unidadeCompra = _normalizarUnidade(widget.insumo?.unidadeCompra);
  late String? _unidadeUso = _normalizarUnidade(widget.insumo?.unidadeUso);
  late final _fatorController = TextEditingController(
    text: widget.insumo == null
        ? ''
        : (widget.insumo!.fatorConversao % 1.0 == 0.0
            ? widget.insumo!.fatorConversao.toInt().toString()
            : widget.insumo!.fatorConversao.toString().replaceAll('.', ',')),
  );
  late final _custoController = TextEditingController(
    text: (widget.insumo?.custoAtual ?? 0) > 0
        ? formatarMoeda(widget.insumo!.custoAtual)
        : '',
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _fatorController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fatorVal = parseDecimalPtBr(_fatorController.text);
    final custoVal = parseDecimalPtBr(_custoController.text);
    final isValid = _nomeController.text.trim().isNotEmpty &&
        _unidadeCompra != null &&
        _unidadeUso != null &&
        fatorVal != null &&
        fatorVal > 0 &&
        (_custoController.text.trim().isEmpty || custoVal != null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                Text(widget.insumo == null ? 'Novo Insumo' : 'Editar Insumo',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: isValid
                      ? () {
                          widget.onConfirm(
                            nome: _nomeController.text.trim(),
                            categoria: _categoria,
                            unidadeCompra: _unidadeCompra!,
                            unidadeUso: _unidadeUso!,
                            fatorConversao: fatorVal,
                            custoAtual: custoVal ?? 0.0,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Salvar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Calabresa',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Insumo'),
                  selected: _categoria == CategoriaInsumo.insumo,
                  onSelected: (_) =>
                      setState(() => _categoria = CategoriaInsumo.insumo),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Embalagem'),
                  selected: _categoria == CategoriaInsumo.embalagem,
                  onSelected: (_) =>
                      setState(() => _categoria = CategoriaInsumo.embalagem),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidadeCompra,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Un. compra'),
                    hint: const Text('Selecionar'),
                    items: _itensUnidade(_unidadeCompra),
                    onChanged: (v) => setState(() => _unidadeCompra = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidadeUso,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Un. uso'),
                    hint: const Text('Selecionar'),
                    items: _itensUnidade(_unidadeUso),
                    onChanged: (v) => setState(() => _unidadeUso = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatorController,
              decoration: const InputDecoration(
                labelText: 'Fator de conversão',
                hintText: 'Ex.: 1000 (1 kg = 1000 g)',
                helperText: 'Quantas unidades de uso cabem em 1 unidade de compra',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _custoController,
              decoration: const InputDecoration(
                labelText: 'Custo por un. de compra (opcional)',
                hintText: 'Ex.: 46,18',
                helperText: 'Atualizado automaticamente pelas compras finalizadas',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
