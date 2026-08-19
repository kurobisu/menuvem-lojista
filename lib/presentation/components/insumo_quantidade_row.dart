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
    // O InkWell cobre só o título/subtítulo, nunca o botão de lixeira -- um
    // IconButton dentro da área de um ListTile.onTap/InkWell maior podia não
    // registrar o toque (nenhum DELETE chegava a sair pra rede, confirmado
    // nos logs do Supabase). Separar as duas regiões elimina a ambiguidade.
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      '$qtdStr $unidade${perdaPercentual > 0 ? ' · perda ${perdaPercentual.toStringAsFixed(0)}%' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text('R\$ ${formatarMoeda(custo)}'),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
