import 'package:flutter/material.dart';

import 'formatters.dart';

/// Linha de insumo com quantidade/unidade/perda e custo, usada tanto na
/// ficha técnica de um produto quanto nos itens de um componente.
class InsumoQuantidadeRow extends StatelessWidget {
  const InsumoQuantidadeRow({
    super.key,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.perdaPercentual,
    required this.custo,
    required this.onTap,
    required this.onDelete,
  });

  final String nome;
  final double quantidade;
  final String unidade;
  final double perdaPercentual;
  final double custo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final qtdStr = quantidade % 1.0 == 0.0
        ? quantidade.toInt().toString()
        : quantidade.toStringAsFixed(2);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(nome),
        subtitle: Text(
          '$qtdStr $unidade${perdaPercentual > 0 ? ' · perda ${perdaPercentual.toStringAsFixed(0)}%' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('R\$ ${formatarMoeda(custo)}'),
            IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
