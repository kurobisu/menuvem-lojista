import '../../data/produto_repository.dart';
import '../model/item_ficha_tecnica.dart';
import '../model/porcao.dart';
import '../model/produto.dart';

/// Cria ou atualiza um produto (id == 0 → insert). Retorna o id do produto.
Future<int> saveProduto(ProdutoRepository repository, Produto produto) async {
  if (produto.id == 0) {
    return repository.insertProduto(produto);
  }
  await repository.updateProduto(produto);
  return produto.id;
}

/// Cria ou atualiza uma porção (id == 0 → insert). Retorna o id da porção.
Future<int> savePorcao(ProdutoRepository repository, Porcao porcao) async {
  if (porcao.id == 0) {
    return repository.insertPorcao(porcao);
  }
  await repository.updatePorcao(porcao);
  return porcao.id;
}

/// Cria um produto já com sua primeira porção. Todo produto precisa ter pelo
/// menos uma porção — produtos de tamanho único ficam com a porção "Única",
/// que a UI esconde. Retorna (produtoId, porcaoId).
Future<(int, int)> criarProdutoComPorcaoInicial(
  ProdutoRepository repository, {
  required String nome,
  String? emoji,
  String nomePorcao = 'Única',
  double margemAlvoPercentual = 30.0,
  double? precoVendaAtual,
}) async {
  final produtoId = await repository.insertProduto(
    Produto(nome: nome, emoji: emoji),
  );
  final porcaoId = await repository.insertPorcao(
    Porcao(
      produtoId: produtoId,
      nome: nomePorcao,
      ordem: 0,
      margemAlvoPercentual: margemAlvoPercentual,
      precoVendaAtual: precoVendaAtual,
    ),
  );
  return (produtoId, porcaoId);
}

/// Adiciona ou atualiza um item da ficha técnica (id == 0 → insert).
Future<int> saveItemFicha(
  ProdutoRepository repository,
  ItemFichaTecnica item,
) async {
  if (item.id == 0) {
    return repository.insertItemFicha(item);
  }
  await repository.updateItemFicha(item);
  return item.id;
}

/// Copia a ficha técnica de uma porção para outra, **substituindo** o que
/// houver no destino (itens soltos e componentes aplicados, com
/// multiplicador). É o que permite criar a porção G a partir da P e só
/// ajustar as quantidades, sem recadastrar tudo.
Future<void> duplicateFichaTecnica(
  ProdutoRepository repository,
  int porcaoOrigemId,
  int porcaoDestinoId,
) async {
  if (porcaoOrigemId == porcaoDestinoId) return;
  final itensOrigem = await repository.getItensFichaByPorcaoOnce(
    porcaoOrigemId,
  );
  final componentesOrigem = await repository.getProdutoComponentesByPorcaoOnce(
    porcaoOrigemId,
  );
  await repository.deleteItensFichaByPorcao(porcaoDestinoId);
  await repository.deleteProdutoComponentesByPorcao(porcaoDestinoId);
  for (final item in itensOrigem) {
    await repository.insertItemFicha(
      item.copyWith(id: 0, porcaoId: porcaoDestinoId),
    );
  }
  for (final vinculo in componentesOrigem) {
    await repository.insertProdutoComponente(
      vinculo.copyWith(id: 0, porcaoId: porcaoDestinoId),
    );
  }
}

/// Cria uma porção nova, opcionalmente copiando a ficha de outra porção do
/// mesmo produto. Retorna o id da porção criada.
Future<int> criarPorcao(
  ProdutoRepository repository, {
  required int produtoId,
  required String nome,
  required int ordem,
  double margemAlvoPercentual = 30.0,
  double? precoVendaAtual,
  int? copiarFichaDaPorcaoId,
}) async {
  final porcaoId = await repository.insertPorcao(
    Porcao(
      produtoId: produtoId,
      nome: nome,
      ordem: ordem,
      margemAlvoPercentual: margemAlvoPercentual,
      precoVendaAtual: precoVendaAtual,
    ),
  );
  if (copiarFichaDaPorcaoId != null) {
    await duplicateFichaTecnica(repository, copiarFichaDaPorcaoId, porcaoId);
  }
  return porcaoId;
}
