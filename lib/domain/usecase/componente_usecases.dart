import 'package:collection/collection.dart';

import '../../data/componente_repository.dart';
import '../../data/produto_repository.dart';
import '../model/componente.dart';
import '../model/item_componente.dart';
import '../model/produto_componente.dart';

/// Cria ou atualiza um componente (id == 0 → insert).
Future<int> saveComponente(
  ComponenteRepository repository,
  Componente componente,
) async {
  if (componente.id == 0) {
    return repository.insertComponente(componente);
  }
  await repository.updateComponente(componente);
  return componente.id;
}

/// Resolve o nome de tipo digitado pelo usuário para o id do
/// [TipoComponente] correspondente, reaproveitando um já cadastrado (nome
/// igual, sem diferenciar maiúsculas/minúsculas) ou criando um novo.
/// Retorna null se [tipoNome] for vazio (componente sem tipo).
Future<int?> resolveTipoComponenteId(
  ComponenteRepository repository,
  String? tipoNome,
) async {
  final nome = tipoNome?.trim();
  if (nome == null || nome.isEmpty) return null;

  final existentes = await repository.getTiposOnce();
  final existente = existentes
      .where((t) => t.nome.toLowerCase() == nome.toLowerCase())
      .firstOrNull;
  if (existente != null) return existente.id;

  return repository.insertTipo(nome);
}

/// Adiciona ou atualiza um item de componente (id == 0 → insert).
Future<int> saveItemComponente(
  ComponenteRepository repository,
  ItemComponente item,
) async {
  if (item.id == 0) {
    return repository.insertItemComponente(item);
  }
  await repository.updateItemComponente(item);
  return item.id;
}

/// Vincula um componente a um produto com o multiplicador aplicado.
/// Ex.: sabor único = 1.0; 2 sabores na mesma massa = 0.5; 3 sabores = 1/3.
Future<int> addComponenteToProduto(
  ProdutoRepository repository, {
  required int produtoId,
  required int componenteId,
  required double multiplicador,
}) {
  return repository.insertProdutoComponente(
    ProdutoComponente(
      produtoId: produtoId,
      componenteId: componenteId,
      multiplicador: multiplicador,
    ),
  );
}

/// Altera o multiplicador de um componente já aplicado a um produto (ex.:
/// de sabor único para metade — 2 sabores na mesma massa).
Future<void> updateProdutoComponenteMultiplicador(
  ProdutoRepository repository,
  ProdutoComponente vinculo,
  double multiplicador,
) {
  return repository.updateProdutoComponente(
    vinculo.copyWith(multiplicador: multiplicador),
  );
}
