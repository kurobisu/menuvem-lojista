import 'tutorial_keys.dart';
import 'tutorial_step.dart';

/// Identificadores das telas com tutorial (usados também como chave do
/// "já viu" no shared_preferences).
class TutorialTela {
  TutorialTela._();
  static const insumos = 'insumos';
  static const componentes = 'componentes';
  static const produtos = 'produtos';
  static const produtoDetalhe = 'produto_detalhe';
}

/// Passos por tela. Cada tutorial explica **só a tela em que o usuário
/// está** — nada de tour que troca de tela sozinho.
List<TutorialStep> passosDaTela(String tela) {
  switch (tela) {
    case TutorialTela.insumos:
      return _insumos;
    case TutorialTela.componentes:
      return _componentes;
    case TutorialTela.produtos:
      return _produtos;
    case TutorialTela.produtoDetalhe:
      return _produtoDetalhe;
    default:
      return const [];
  }
}

final _insumos = <TutorialStep>[
  const TutorialStep(
    titulo: 'Insumos: a base de tudo',
    descricao:
        'Aqui ficam os ingredientes e embalagens que você compra. O custo '
        'dos seus produtos é calculado a partir daqui — então comece por '
        'esta tela.',
  ),
  TutorialStep(
    titulo: 'Cadastre um insumo',
    descricao:
        'Informe como você COMPRA (o kg, a caixa) e como USA na receita '
        '(gramas, unidades). Cada campo do formulário tem um "?" com '
        'exemplo, se a nomenclatura confundir.',
    targetKey: TutorialKeys.insumosNovo,
  ),
  TutorialStep(
    titulo: 'Preço sempre atualizado',
    descricao:
        'Cada insumo mostra o custo na unidade de compra e na de uso. Ao '
        'finalizar uma lista de compras, o preço aqui se atualiza sozinho e '
        'todos os produtos que usam esse insumo recalculam o custo.',
    targetKey: TutorialKeys.insumosLista,
  ),
];

final _componentes = <TutorialStep>[
  const TutorialStep(
    titulo: 'Componentes: blocos reutilizáveis',
    descricao:
        'Um componente é um conjunto de insumos que se repete em vários '
        'produtos — a massa da pizza, um recheio, a embalagem. Cadastre uma '
        'vez e reaproveite.',
  ),
  TutorialStep(
    titulo: 'Crie um componente',
    descricao:
        'Dê um nome (ex.: "Massa 35cm") e adicione os insumos com as '
        'quantidades. Ao mudar o preço de um insumo, todos os produtos que '
        'usam este bloco se ajustam de uma vez.',
    targetKey: TutorialKeys.componentesNovo,
  ),
  TutorialStep(
    titulo: 'Dividir entre sabores',
    descricao:
        'Ao aplicar um componente num produto, você escolhe a fração usada: '
        'inteiro, 1/2 (pizza meio a meio), 1/3... O custo entra '
        'proporcionalmente.',
    targetKey: TutorialKeys.componentesLista,
  ),
];

final _produtos = <TutorialStep>[
  const TutorialStep(
    titulo: 'Produtos: o que você vende',
    descricao:
        'Cada produto tem uma ficha técnica (os insumos que entram nele) e, '
        'a partir dela, o app calcula o custo, o preço sugerido e a margem.',
  ),
  TutorialStep(
    titulo: 'Crie um produto',
    descricao:
        'Informe o nome, a margem de lucro que você quer e, se já vender, o '
        'preço praticado hoje. Depois é só montar a ficha técnica.',
    targetKey: TutorialKeys.produtosNovo,
  ),
  TutorialStep(
    titulo: 'Custo e margem à vista',
    descricao:
        'A lista mostra o custo e o preço sugerido de cada produto. Um '
        'triângulo de alerta aparece quando o preço que você cobra deixou de '
        'cobrir a margem-alvo.',
    targetKey: TutorialKeys.produtosLista,
  ),
];

final _produtoDetalhe = <TutorialStep>[
  TutorialStep(
    titulo: 'Tamanhos do mesmo produto',
    descricao:
        'Uma pizza pode ser P, M e G sem virar três produtos: cada tamanho é '
        'uma porção, com sua própria ficha técnica, margem e preço. Ao criar '
        'um tamanho novo, dá para copiar a ficha de outro e só ajustar as '
        'quantidades.',
    targetKey: TutorialKeys.produtoPorcoes,
  ),
  TutorialStep(
    titulo: 'Custo e preço sugerido',
    descricao:
        'O custo vem da soma da ficha técnica desta porção. O preço sugerido '
        'é quanto cobrar para bater a margem-alvo. Use o lápis para ajustar '
        'margem e preço praticado.',
    targetKey: TutorialKeys.produtoResumoCusto,
  ),
  TutorialStep(
    titulo: 'Monte a ficha técnica',
    descricao:
        '"Componente" aplica um bloco pronto (massa, recheio). "Insumo" '
        'adiciona um ingrediente avulso. "Copiar" traz a ficha de outro '
        'tamanho deste mesmo produto.',
    targetKey: TutorialKeys.produtoAcoesFicha,
  ),
];
