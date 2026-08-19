import 'package:collection/collection.dart';

import '../../data/componente_repository.dart';
import '../../data/produto_repository.dart';
import '../model/componente.dart';
import '../model/item_componente.dart';
import '../model/produto_componente.dart';
import '../model/tamanho_componente.dart';

/// Cria ou atualiza um componente (id == 0 → insert). Não mexe em tamanhos —
/// para criar um componente novo já com seu primeiro tamanho, use
/// [criarComponenteComTamanhoInicial].
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

/// Cria um componente já com seu primeiro tamanho. Todo componente precisa
/// ter pelo menos um tamanho — componentes sem variação ficam com o tamanho
/// "Único", que a UI esconde. Retorna (componenteId, tamanhoId).
Future<(int, int)> criarComponenteComTamanhoInicial(
  ComponenteRepository repository, {
  required String nome,
  int? tipoComponenteId,
  String? emoji,
  required int ordem,
  String nomeTamanho = 'Único',
}) async {
  final componenteId = await repository.insertComponente(
    Componente(
      nome: nome,
      tipoComponenteId: tipoComponenteId,
      emoji: emoji,
      ordem: ordem,
    ),
  );
  final tamanhoId = await repository.insertTamanho(
    TamanhoComponente(componenteId: componenteId, nome: nomeTamanho, ordem: 0),
  );
  return (componenteId, tamanhoId);
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

  return repository.insertTipo(nome, ordem: existentes.length);
}

/// Cria ou atualiza um tamanho de componente (id == 0 → insert).
Future<int> saveTamanhoComponente(
  ComponenteRepository repository,
  TamanhoComponente tamanho,
) async {
  if (tamanho.id == 0) {
    return repository.insertTamanho(tamanho);
  }
  await repository.updateTamanho(tamanho);
  return tamanho.id;
}

/// Copia os itens de [tamanhoOrigemId] para [tamanhoDestinoId],
/// **substituindo** o que houver no destino. É o que permite criar um
/// tamanho novo a partir do "Único" e só ajustar as quantidades.
Future<void> duplicarItensTamanho(
  ComponenteRepository repository,
  int tamanhoOrigemId,
  int tamanhoDestinoId,
) async {
  if (tamanhoOrigemId == tamanhoDestinoId) return;
  final itensOrigem = await repository.getItensByTamanhoOnce(tamanhoOrigemId);
  await repository.deleteItensByTamanho(tamanhoDestinoId);
  for (final item in itensOrigem) {
    await repository.insertItemComponente(
      item.copyWith(id: 0, tamanhoComponenteId: tamanhoDestinoId),
    );
  }
}

/// Cria um tamanho novo para um componente, opcionalmente copiando os itens
/// de outro tamanho do mesmo componente. Retorna o id do tamanho criado.
Future<int> criarTamanho(
  ComponenteRepository repository, {
  required int componenteId,
  required String nome,
  required int ordem,
  int? copiarItensDoTamanhoId,
}) async {
  final tamanhoId = await repository.insertTamanho(
    TamanhoComponente(componenteId: componenteId, nome: nome, ordem: ordem),
  );
  if (copiarItensDoTamanhoId != null) {
    await duplicarItensTamanho(repository, copiarItensDoTamanhoId, tamanhoId);
  }
  return tamanhoId;
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

/// Vincula um componente (num tamanho específico dele) a uma porção, com o
/// multiplicador aplicado. Ex.: sabor único = 1.0; 2 sabores na mesma massa
/// = 0.5; 3 sabores = 1/3.
Future<int> addComponenteToPorcao(
  ProdutoRepository repository, {
  required int porcaoId,
  required int componenteId,
  required int tamanhoComponenteId,
  required double multiplicador,
}) {
  return repository.insertProdutoComponente(
    ProdutoComponente(
      porcaoId: porcaoId,
      componenteId: componenteId,
      tamanhoComponenteId: tamanhoComponenteId,
      multiplicador: multiplicador,
    ),
  );
}

/// Altera o multiplicador de um componente já aplicado a uma porção (ex.:
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

/// Duplica um componente com **todos os seus tamanhos** e os itens de cada
/// um -- permite reaproveitar um bloco pronto (ex.: uma massa já
/// configurada, com suas variações de tamanho) e só ajustar as quantidades,
/// sem recadastrar cada insumo do zero. Retorna o id do componente novo.
Future<int> duplicarComponente(
  ComponenteRepository repository,
  Componente original, {
  required int ordem,
}) async {
  final tamanhosOrigem = await repository.getTamanhosByComponenteOnce(
    original.id,
  );
  final novoId = await repository.insertComponente(
    original.copyWith(id: 0, nome: '${original.nome} (cópia)', ordem: ordem),
  );
  for (final tamanho in tamanhosOrigem) {
    final novoTamanhoId = await repository.insertTamanho(
      tamanho.copyWith(id: 0, componenteId: novoId),
    );
    final itensOrigem = await repository.getItensByTamanhoOnce(tamanho.id);
    for (final item in itensOrigem) {
      await repository.insertItemComponente(
        item.copyWith(id: 0, tamanhoComponenteId: novoTamanhoId),
      );
    }
  }
  return novoId;
}
