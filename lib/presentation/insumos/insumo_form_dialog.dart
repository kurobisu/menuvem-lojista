import 'package:flutter/material.dart';

import '../../domain/model/categoria_insumo.dart';
import '../../domain/model/insumo.dart';
import '../components/campo_com_ajuda.dart';
import '../components/emoji_picker_field.dart';
import '../components/emojis.dart';
import '../components/form_sheet_header.dart';
import '../components/formatters.dart';
import '../components/unidades_medida.dart';

typedef InsumoFormConfirm =
    void Function({
      required String nome,
      required CategoriaInsumo categoria,
      required String unidadeCompra,
      required String unidadeUso,
      required double fatorConversao,
      required double custoAtual,
      String? emoji,
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
  const InsumoFormDialog({super.key, this.insumo, required this.onConfirm});

  final Insumo? insumo;
  final InsumoFormConfirm onConfirm;

  @override
  State<InsumoFormDialog> createState() => _InsumoFormDialogState();
}

class _InsumoFormDialogState extends State<InsumoFormDialog> {
  late final _nomeController = TextEditingController(
    text: widget.insumo?.nome ?? '',
  );
  late CategoriaInsumo _categoria =
      widget.insumo?.categoria ?? CategoriaInsumo.insumo;
  late String? _unidadeCompra = _normalizarUnidade(
    widget.insumo?.unidadeCompra,
  );
  late String? _unidadeUso = _normalizarUnidade(widget.insumo?.unidadeUso);
  late String? _emoji = widget.insumo?.emoji;
  late final _fatorController = TextEditingController(
    text: widget.insumo == null
        ? ''
        : _formatarNumero(widget.insumo!.fatorConversao),
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

  static String _formatarNumero(double valor) {
    return valor % 1.0 == 0.0
        ? valor.toInt().toString()
        : valor.toString().replaceAll('.', ',');
  }

  void _preencherFatorObvio() {
    final compra = _unidadeCompra;
    final uso = _unidadeUso;
    if (compra == null || uso == null) return;
    final fator = fatorConversaoObvio(compra, uso);
    if (fator != null) _fatorController.text = _formatarNumero(fator);
  }

  @override
  Widget build(BuildContext context) {
    final fatorVal = parseDecimalPtBr(_fatorController.text);
    final custoVal = parseMoedaPtBr(_custoController.text);
    final isValid =
        _nomeController.text.trim().isNotEmpty &&
        _unidadeCompra != null &&
        _unidadeUso != null &&
        fatorVal != null &&
        fatorVal > 0 &&
        (_custoController.text.trim().isEmpty || custoVal != null);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSheetHeader(
              titulo: widget.insumo == null ? 'Novo Insumo' : 'Editar Insumo',
              onCancelar: () => Navigator.of(context).pop(),
              onSalvar: isValid
                  ? () {
                      widget.onConfirm(
                        nome: _nomeController.text.trim(),
                        categoria: _categoria,
                        unidadeCompra: _unidadeCompra!,
                        unidadeUso: _unidadeUso!,
                        fatorConversao: fatorVal,
                        custoAtual: custoVal ?? 0.0,
                        emoji: _emoji,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
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
            Text(
              'Ícone (opcional)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            EmojiPickerField(
              opcoes: emojisInsumo,
              selecionado: _emoji,
              onChanged: (v) => setState(() => _emoji = v),
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
            const RotuloComAjuda(
              rotulo: 'Unidades',
              titulo: 'Unidade de compra e de uso',
              explicacao:
                  'A unidade de COMPRA é como o produto vem do fornecedor '
                  '(o quilo, a caixa, o fardo). A unidade de USO é como ele '
                  'entra na receita (gramas, ml, unidades).\n\n'
                  'Podem ser iguais — ovo você compra e usa por unidade.',
              exemplo: 'Farinha: compra em kg, usa em g.',
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidadeCompra,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Un. compra'),
                    hint: const Text('Selecionar'),
                    items: _itensUnidade(_unidadeCompra),
                    onChanged: (v) => setState(() {
                      _unidadeCompra = v;
                      _preencherFatorObvio();
                    }),
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
                    onChanged: (v) => setState(() {
                      _unidadeUso = v;
                      _preencherFatorObvio();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatorController,
              decoration: const InputDecoration(
                labelText: 'Fator de conversão',
                hintText: 'Ex.: 1000',
                helperText:
                    'Quantas unidades de uso cabem em 1 unidade de compra',
                suffixIcon: AjudaIconButton(
                  titulo: 'Fator de conversão',
                  explicacao:
                      'Quantas unidades de USO cabem em 1 unidade de COMPRA. '
                      'É o que permite ao app saber quanto custa a grama a '
                      'partir do preço do quilo.\n\n'
                      'Se você compra e usa na mesma unidade, o fator é 1.',
                  exemplo:
                      '1 kg de farinha = 1000 g → fator 1000.\n'
                      '1 caixa com 30 ovos = 30 un → fator 30.',
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _custoController,
              inputFormatters: const [MoedaInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Custo por un. de compra (opcional)',
                hintText: '0,00',
                helperText:
                    'Atualizado automaticamente pelas compras finalizadas',
                suffixIcon: AjudaIconButton(
                  titulo: 'Custo por unidade de compra',
                  explicacao:
                      'Quanto você paga na unidade em que COMPRA — o preço do '
                      'quilo, da caixa, do fardo. Não é o preço da grama.\n\n'
                      'Pode deixar em branco: ao finalizar uma lista de '
                      'compras, o app preenche sozinho com o que você pagou.',
                  exemplo:
                      'Comprou o kg de calabresa por R\$ 46,18 → informe 46,18.',
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
