import '../../data/produto_repository.dart';
import '../model/item_ficha_tecnica.dart';
import '../model/produto.dart';

/// Cria ou atualiza um produto (id == 0 → insert). Retorna o id do produto.
Future<int> saveProduto(ProdutoRepository repository, Produto produto) async {
  if (produto.id == 0) {
    return repository.insertProduto(produto);
  }
  await repository.updateProduto(produto);
  return produto.id;
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

/// Copia a ficha técnica de um produto para outro, substituindo os itens
/// atuais do destino (itens soltos e componentes aplicados, com
/// multiplicador). Atalho para cadastrar variações (Pizza P/M/G), combos e
/// cópias que depois podem ser editadas (ex.: "Hambúrguer de Calabresa"
/// usando a mesma base).
Future<void> duplicateFichaTecnica(
  ProdutoRepository repository,
  int produtoOrigemId,
  int produtoDestinoId,
) async {
  if (produtoOrigemId == produtoDestinoId) return;
  final itensOrigem = await repository.getItensFichaByProduto(produtoOrigemId).first;
  final componentesOrigem =
      await repository.getProdutoComponentesByProdutoOnce(produtoOrigemId);
  await repository.deleteItensFichaByProduto(produtoDestinoId);
  await repository.deleteProdutoComponentesByProduto(produtoDestinoId);
  for (final item in itensOrigem) {
    await repository.insertItemFicha(
      item.copyWith(id: 0, produtoId: produtoDestinoId),
    );
  }
  for (final vinculo in componentesOrigem) {
    await repository.insertProdutoComponente(
      vinculo.copyWith(id: 0, produtoId: produtoDestinoId),
    );
  }
}
