import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botão de voltar da AppBar que nunca deixa o usuário sem saída: usa o
/// back padrão quando há pilha de navegação para desempilhar, ou leva para
/// a Home quando não há (acesso direto pela URL, ou refresh da página no
/// build web — nesses casos a pilha do Navigator nasce vazia e o
/// `automaticallyImplyLeading` do AppBar não mostra nada).
class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      return const BackButton();
    }
    return IconButton(
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Início',
      onPressed: () => context.go('/home'),
    );
  }
}
