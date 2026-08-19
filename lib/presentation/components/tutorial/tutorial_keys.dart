import 'package:flutter/widgets.dart';

/// `GlobalKey`s dos widgets destacados pelo tutorial, centralizadas para não
/// espalhar keys soltas pelas telas.
///
/// Cada tela marca seus alvos com estas keys e monta sua própria lista de
/// passos (ver `tutorial_passos.dart`). São `static final` porque uma
/// `GlobalKey` precisa ser única e estável entre rebuilds.
class TutorialKeys {
  TutorialKeys._();

  // Insumos
  static final insumosNovo = GlobalKey();
  static final insumosFiltros = GlobalKey();
  static final insumosLista = GlobalKey();

  // Componentes
  static final componentesNovo = GlobalKey();
  static final componentesLista = GlobalKey();

  // Produtos
  static final produtosNovo = GlobalKey();
  static final produtosLista = GlobalKey();

  // Detalhe do produto (ficha técnica)
  static final produtoPorcoes = GlobalKey();
  static final produtoResumoCusto = GlobalKey();
  static final produtoAcoesFicha = GlobalKey();
}
