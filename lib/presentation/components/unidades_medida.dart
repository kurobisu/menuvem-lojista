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

/// Fator de conversão óbvio para o par (compra → uso), quando existe uma
/// relação fixa e universal — 1 kg são sempre 1000 g, não importa o insumo.
/// Devolve null para pares como caixa→unidade, que variam por insumo (uma
/// caixa de ovos tem 30 un, uma de leite tem 12) e por isso não têm valor
/// óbvio a sugerir; o usuário digita esse caso manualmente.
double? fatorConversaoObvio(String unidadeCompra, String unidadeUso) {
  final compra = unidadeCompra.toLowerCase();
  final uso = unidadeUso.toLowerCase();
  if (compra == uso) return 1;
  if (compra == 'kg' && uso == 'g') return 1000;
  if (compra == 'g' && uso == 'kg') return 0.001;
  if (compra == 'l' && uso == 'ml') return 1000;
  if (compra == 'ml' && uso == 'l') return 0.001;
  if (compra == 'dz' && uso == 'un') return 12;
  if (compra == 'un' && uso == 'dz') return 1 / 12;
  return null;
}
