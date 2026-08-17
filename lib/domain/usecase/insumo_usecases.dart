import '../../data/componente_repository.dart';
import '../../data/insumo_repository.dart';
import '../../data/produto_repository.dart';
import '../model/insumo.dart';

/// Cria ou atualiza um insumo (id == 0 → insert). Retorna o id do insumo.
/// O custo informado manualmente funciona como override do preço vindo do
/// histórico de compras.
Future<int> saveInsumo(InsumoRepository repository, Insumo insumo) async {
  if (insumo.id == 0) {
    return repository.insertInsumo(insumo);
  }
  await repository.updateInsumo(insumo);
  return insumo.id;
}

/// Exclui um insumo, desde que ele não seja usado em nenhuma ficha técnica
/// nem em nenhum componente (FK é RESTRICT — esta verificação evita o erro
/// no banco e devolve mensagem amigável).
///
/// Retorna mensagem de erro se o insumo estiver em uso; null se excluiu.
Future<String?> deleteInsumo({
  required InsumoRepository insumoRepository,
  required ProdutoRepository produtoRepository,
  required ComponenteRepository componenteRepository,
  required Insumo insumo,
}) async {
  final usosFicha = await produtoRepository.getItensFichaByInsumo(insumo.id);
  if (usosFicha.isNotEmpty) {
    return 'Usado em ${usosFicha.length} ficha(s) técnica(s) — remova-o das fichas antes de excluir';
  }
  final usosComponente = await componenteRepository.getItensByInsumo(insumo.id);
  if (usosComponente.isNotEmpty) {
    return 'Usado em ${usosComponente.length} componente(s) — remova-o antes de excluir';
  }
  await insumoRepository.deleteInsumo(insumo);
  return null;
}
