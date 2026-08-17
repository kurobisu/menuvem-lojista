import '../../data/historico_preco_repository.dart';
import '../../data/insumo_repository.dart';
import '../../data/lista_compras_repository.dart';
import '../model/historico_preco.dart';
import '../model/insumo.dart';
import '../model/item_lista.dart';
import '../model/lista_compras.dart';

/// Cria uma nova lista de compras com o nome fornecido. Retorna o ID criado.
Future<int> createListaCompras(ListaComprasRepository repository, String nome) {
  return repository.insertLista(ListaCompras(nome: nome.trim()));
}

/// Adiciona um item à lista — livre (digitado) ou vinculado a um insumo
/// cadastrado.
Future<int> addItemToLista(
  ListaComprasRepository repository, {
  required int listaId,
  required String nomeItem,
  required double quantidade,
  required String unidade,
  double precoUnitario = 0.0,
  Insumo? insumo,
}) {
  final item = ItemLista(
    listaComprasId: listaId,
    insumoId: insumo?.id,
    nomeItem: insumo != null ? insumo.nome : nomeItem.trim(),
    quantidade: quantidade,
    unidade: insumo != null ? insumo.unidadeCompra : unidade,
    precoUnitario: insumo != null && precoUnitario <= 0.0
        ? insumo.custoAtual
        : precoUnitario,
  );
  return repository.insertItem(item);
}

/// Finaliza uma lista de compras:
/// 1. Coleta snapshot dos itens e da lista.
/// 2. Para cada item comprado vinculado a insumo: registra o histórico de
///    preço e atualiza o custo atual do insumo (LIFO — último preço pago).
/// 3. Calcula o total gasto e marca a lista como finalizada.
Future<void> finalizarCompra(
  int listaId, {
  required ListaComprasRepository listaRepository,
  required InsumoRepository insumoRepository,
  required HistoricoPrecoRepository historicoRepository,
}) async {
  final itens = await listaRepository.getItensByLista(listaId).first;
  final lista = await listaRepository.getListaById(listaId).first;
  if (lista == null) return;

  final totalGasto = itens
      .where((i) => i.comprado)
      .fold<double>(0.0, (sum, i) => sum + i.precoTotal);

  for (final item in itens) {
    if (item.comprado && item.insumoId != null && item.precoUnitario > 0) {
      await historicoRepository.insertHistorico(
        HistoricoPreco(
          insumoId: item.insumoId!,
          preco: item.precoUnitario,
          listaComprasId: listaId,
          listaComprasNome: lista.nome,
        ),
      );
      await insumoRepository.updateCustoInsumo(item.insumoId!, item.precoUnitario);
    }
  }

  await listaRepository.updateLista(
    lista.copyWith(
      status: StatusLista.finalizada,
      dataFinalizacao: DateTime.now(),
      totalGasto: totalGasto,
    ),
  );
}
