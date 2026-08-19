import 'package:flutter/material.dart';

/// Uma unidade de medida selecionável nos campos de unidade de compra/uso do
/// insumo (ver `insumo_form_dialog.dart`). Lista fechada — sem opção de texto
/// livre, por decisão do dono do projeto.
class UnidadeMedida {
  const UnidadeMedida(this.valor, this.rotulo, this.icone);
  final String valor;
  final String rotulo;
  final IconData icone;
}

const unidadesMedida = [
  UnidadeMedida('kg', 'Quilograma (kg)', Icons.scale),
  UnidadeMedida('g', 'Grama (g)', Icons.scale),
  UnidadeMedida('L', 'Litro (L)', Icons.liquor),
  UnidadeMedida('ml', 'Mililitro (ml)', Icons.liquor),
  UnidadeMedida('un', 'Unidade (un)', Icons.inventory_2),
  UnidadeMedida('cx', 'Caixa (cx)', Icons.inventory_2),
  UnidadeMedida('pct', 'Pacote (pct)', Icons.inventory_2),
  UnidadeMedida('dz', 'Dúzia (dz)', Icons.inventory_2),
  UnidadeMedida('fardo', 'Fardo', Icons.inventory_2),
];

/// Ícone da unidade [valor] (comparação sem diferenciar maiúsculas de
/// minúsculas). Cai em [Icons.inventory_2] se não bater com nenhum preset —
/// caso de insumos cadastrados antes desta lista existir.
IconData iconeUnidade(String valor) {
  for (final u in unidadesMedida) {
    if (u.valor.toLowerCase() == valor.toLowerCase()) return u.icone;
  }
  return Icons.inventory_2;
}
