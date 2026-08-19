import 'package:flutter/material.dart';

import '../../domain/model/porcao.dart';
import '../components/campo_com_ajuda.dart';
import '../components/form_sheet_header.dart';
import '../components/formatters.dart';

typedef PorcaoFormConfirm =
    void Function({
      required String nome,
      required double margemAlvo,
      double? precoVenda,
      int? copiarFichaDaPorcaoId,
    });

/// Folha de criação/edição de porção (o tamanho vendável de um produto).
///
/// Na criação, quando o produto já tem outras porções, oferece copiar a
/// ficha técnica de uma delas — é o caminho normal de P → G, onde muda só a
/// quantidade dos mesmos insumos.
class PorcaoFormDialog extends StatefulWidget {
  const PorcaoFormDialog({
    super.key,
    this.porcao,
    this.porcoesParaCopiar = const [],
    required this.margemPadrao,
    required this.onConfirm,
  });

  /// Null = criação.
  final Porcao? porcao;

  /// Porções existentes cuja ficha pode ser copiada (vazio na criação do
  /// primeiro tamanho, ou sempre vazio na edição).
  final List<Porcao> porcoesParaCopiar;

  /// Margem sugerida por padrão (normalmente a da última porção criada).
  final double margemPadrao;

  final PorcaoFormConfirm onConfirm;

  @override
  State<PorcaoFormDialog> createState() => _PorcaoFormDialogState();
}

class _PorcaoFormDialogState extends State<PorcaoFormDialog> {
  late final _nomeController = TextEditingController(
    text: widget.porcao?.nome ?? '',
  );
  late final _margemController = TextEditingController(
    text: _formatarNumero(
      widget.porcao?.margemAlvoPercentual ?? widget.margemPadrao,
    ),
  );
  late final _precoController = TextEditingController(
    text: widget.porcao?.precoVendaAtual != null
        ? formatarMoeda(widget.porcao!.precoVendaAtual!)
        : '',
  );

  /// Porção cuja ficha será copiada; null = começar vazia.
  int? _copiarDe;

  bool get _isCriacao => widget.porcao == null;

  static String _formatarNumero(double valor) {
    return valor % 1.0 == 0.0
        ? valor.toInt().toString()
        : valor.toString().replaceAll('.', ',');
  }

  @override
  void initState() {
    super.initState();
    // Copiar da primeira porção é o caso comum ao criar um tamanho novo.
    if (_isCriacao && widget.porcoesParaCopiar.isNotEmpty) {
      _copiarDe = widget.porcoesParaCopiar.first.id;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _margemController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final margemVal = parseDecimalPtBr(_margemController.text);
    final precoVal = parseMoedaPtBr(_precoController.text);
    final isValid =
        _nomeController.text.trim().isNotEmpty &&
        margemVal != null &&
        margemVal >= 0 &&
        margemVal <= 99.9 &&
        (_precoController.text.trim().isEmpty || precoVal != null);

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
              titulo: _isCriacao ? 'Nova Porção' : 'Editar Porção',
              onCancelar: () => Navigator.of(context).pop(),
              onSalvar: isValid
                  ? () {
                      widget.onConfirm(
                        nome: _nomeController.text.trim(),
                        margemAlvo: margemVal,
                        precoVenda: _precoController.text.trim().isEmpty
                            ? null
                            : precoVal,
                        copiarFichaDaPorcaoId: _isCriacao ? _copiarDe : null,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do tamanho',
                hintText: 'Ex.: G, Família, 35cm',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _margemController,
              decoration: const InputDecoration(
                labelText: 'Margem de lucro alvo (%)',
                suffixIcon: AjudaIconButton(
                  titulo: 'Margem de lucro alvo',
                  explicacao:
                      'Quanto do preço de venda você quer que sobre depois de '
                      'pagar os insumos. O app usa isso para calcular o preço '
                      'sugerido a partir do custo da ficha técnica.\n\n'
                      'É margem sobre o PREÇO, não markup sobre o custo.',
                  exemplo:
                      'Custo R\$ 14,00 com margem 30% → preço sugerido '
                      'R\$ 20,00 (R\$ 6,00 sobram, que são 30% de R\$ 20,00).',
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precoController,
              inputFormatters: const [MoedaInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Preço de venda atual (opcional)',
                hintText: '0,00',
                suffixIcon: AjudaIconButton(
                  titulo: 'Preço de venda atual',
                  explicacao:
                      'O preço que você cobra hoje por esta porção. Serve só '
                      'para comparação: o app mostra a margem real que esse '
                      'preço dá e avisa quando ela cai abaixo da sua meta '
                      '(por exemplo, quando um insumo encarece).\n\n'
                      'Deixe em branco se ainda não vende ou não quer '
                      'acompanhar.',
                  exemplo:
                      'Preço R\$ 18,00 com custo R\$ 14,00 → margem real '
                      '22,2%. Com meta de 30%, o app alerta.',
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            if (_isCriacao && widget.porcoesParaCopiar.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Ficha técnica',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Copie de outro tamanho e ajuste só as quantidades.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<int?>(
                groupValue: _copiarDe,
                onChanged: (v) => setState(() => _copiarDe = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in widget.porcoesParaCopiar)
                      RadioListTile<int?>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: p.id,
                        title: Text('Copiar de "${p.nome}"'),
                      ),
                    const RadioListTile<int?>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: null,
                      title: Text('Começar vazia'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
