import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/app_version.dart';
import '../../domain/model/lista_compras.dart';
import '../../domain/model/porcao_com_custo.dart';
import '../../domain/model/produto.dart';
import '../../domain/model/tendencia_preco.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_theme.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/responsive.dart';
import '../components/tendencia_indicador.dart';
import 'home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);

    return Scaffold(
      body: MaxWidthCenter(
        maxWidth: kDashboardMaxWidth,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [purplePrimary, purpleLight],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Menuvem',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    appVersionLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                              Text(
                                'Lojista',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.push('/price-history'),
                                icon: const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                ),
                                tooltip: 'Histórico de preços',
                              ),
                              IconButton(
                                onPressed: () => context.push('/trocar-conta'),
                                icon: const Icon(
                                  Icons.switch_account,
                                  color: Colors.white,
                                ),
                                tooltip: 'Trocar de conta',
                              ),
                              IconButton(
                                onPressed: () =>
                                    ref.read(authRepositoryProvider).signOut(),
                                icon: const Icon(
                                  Icons.exit_to_app,
                                  color: Colors.white,
                                ),
                                tooltip: 'Sair',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      homeData.maybeWhen(
                        data: (data) => data.ultimaLista != null
                            ? _UltimaListaCard(
                                lista: data.ultimaLista!,
                                onTap: () => context.go(
                                  '/shopping-lists/${data.ultimaLista!.id}',
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _SectionHeader(title: 'Precificação')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PrecificacaoCard(
                        titulo: 'Produtos',
                        subtitulo: 'Fichas técnicas e preços',
                        icon: Icons.restaurant_outlined,
                        onTap: () => context.push('/produtos'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrecificacaoCard(
                        titulo: 'Componentes',
                        subtitulo: 'Blocos reutilizáveis',
                        icon: Icons.widgets,
                        onTap: () => context.push('/componentes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrecificacaoCard(
                        titulo: 'Insumos',
                        subtitulo: 'Biblioteca e custos',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => context.push('/insumos'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            homeData.maybeWhen(
              data: (data) {
                if (data.porcoesAbaixoDaMeta.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverList.list(
                  children: [
                    _SectionHeader(title: 'Alertas de Margem'),
                    ...data.porcoesAbaixoDaMeta.map(
                      (alerta) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: _AlertaMargemRow(
                          produto: alerta.produto,
                          item: alerta.porcao,
                          onTap: () =>
                              context.push('/produtos/${alerta.produto.id}'),
                        ),
                      ),
                    ),
                  ],
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Listas Recentes',
                action: 'Ver todas',
                onAction: () => context.push('/shopping-lists'),
              ),
            ),
            homeData.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: purplePrimary),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('Erro: $e')),
                ),
              ),
              data: (data) {
                if (data.todasListas.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Nenhuma lista ainda',
                      subtitle:
                          'Crie sua primeira lista de compras tocando no botão +',
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 132,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: data.todasListas
                          .take(5)
                          .map(
                            (lista) => _ListaResumoCard(
                              lista: lista,
                              onTap: () =>
                                  context.push('/shopping-lists/${lista.id}'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Variação de Preços',
                action: 'Histórico completo',
                onAction: () => context.push('/price-history'),
              ),
            ),
            homeData.maybeWhen(
              data: (data) {
                if (data.insumosComTendencia.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.insights_outlined,
                      title: 'Sem dados de variação',
                      subtitle:
                          'Finalize listas de compras para ver tendências de preço',
                    ),
                  );
                }
                final ordenados = [...data.insumosComTendencia]
                  ..sort(
                    (a, b) => (b.tendencia == TendenciaPreco.alta ? 1 : 0)
                        .compareTo(a.tendencia == TendenciaPreco.alta ? 1 : 0),
                  );
                return SliverList.list(
                  children: ordenados
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: _InsumoTendenciaRow(
                            item: item,
                            onTap: () => context.push(
                              '/price-history/${item.insumo.id}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shopping-lists'),
        backgroundColor: yellowSecondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Lista'),
      ),
    );
  }
}

class _UltimaListaCard extends StatelessWidget {
  const _UltimaListaCard({required this.lista, required this.onTap});
  final ListaCompras lista;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd('pt_BR');
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lista.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: Colors.white),
                    ),
                    Text(
                      formatter.format(lista.dataCriacao),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lista.totalGasto > 0)
                    Text(
                      'R\$ ${formatarMoeda(lista.totalGasto)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: yellowSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (lista.status == StatusLista.aberta
                                  ? yellowContainer
                                  : successContainer)
                              .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      lista.status == StatusLista.aberta
                          ? 'Aberta'
                          : 'Finalizada',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaResumoCard extends StatelessWidget {
  const _ListaResumoCard({required this.lista, required this.onTap});
  final ListaCompras lista;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM');
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lista.status == StatusLista.finalizada
                      ? Icons.check_circle
                      : Icons.shopping_cart,
                  color: lista.status == StatusLista.finalizada
                      ? successGreen
                      : purplePrimary,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  lista.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(lista.dataCriacao),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (lista.totalGasto > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${formatarMoeda(lista.totalGasto)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: purplePrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsumoTendenciaRow extends StatelessWidget {
  const _InsumoTendenciaRow({required this.item, required this.onTap});
  final InsumoComTendencia item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.insumo.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'por ${item.insumo.unidadeCompra}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${formatarMoeda(item.ultimoPreco)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TendenciaIndicador(
                    tendencia: item.tendencia,
                    showLabel: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrecificacaoCard extends StatelessWidget {
  const _PrecificacaoCard({
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.onTap,
  });
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: purplePrimary, size: 28),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitulo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertaMargemRow extends StatelessWidget {
  const _AlertaMargemRow({
    required this.produto,
    required this.item,
    required this.onTap,
  });
  final Produto produto;
  final PorcaoComCusto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.warning, color: warningOrange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${produto.nome} · ${item.porcao.nome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Margem ${(item.margemRealPercentual ?? 0.0).toStringAsFixed(1)}% · '
                      'meta ${item.porcao.margemAlvoPercentual.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${formatarMoeda(item.precoSugerido)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: purplePrimary,
                    ),
                  ),
                  Text(
                    'preço sugerido',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(color: purplePrimary),
              ),
            ),
        ],
      ),
    );
  }
}
