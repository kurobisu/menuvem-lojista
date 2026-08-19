import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'tutorial_controller.dart';

/// Camada que escurece a tela, recorta um "buraco" em volta do widget do
/// passo atual e mostra um balão explicativo perto dele.
///
/// Fica montada uma única vez na raiz (via `MaterialApp.builder`) e só
/// desenha algo quando há um tutorial ativo.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  Rect? _alvo;
  int? _indiceMedido;

  /// Mede o widget-alvo depois do frame. O alvo pode ainda não estar montado
  /// (lista carregando, item fora da tela), então tenta algumas vezes antes
  /// de desistir e cair no cartão centralizado.
  void _medirAlvo(int indice, GlobalKey? key, {int tentativa = 0}) {
    if (key == null) {
      if (mounted && _alvo != null) setState(() => _alvo = null);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final estado = ref.read(tutorialProvider);
      if (!estado.ativo || estado.indice != indice) return;

      final ctx = key.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        if (tentativa < 10) {
          Future.delayed(const Duration(milliseconds: 80), () {
            if (mounted) _medirAlvo(indice, key, tentativa: tentativa + 1);
          });
        } else if (_alvo != null) {
          setState(() => _alvo = null);
        }
        return;
      }
      final origem = box.localToGlobal(Offset.zero);
      final rect = origem & box.size;
      if (_alvo != rect) setState(() => _alvo = rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(tutorialProvider);
    final passo = estado.passoAtual;
    if (passo == null) return const SizedBox.shrink();

    if (_indiceMedido != estado.indice) {
      _indiceMedido = estado.indice;
      _alvo = null;
      _medirAlvo(estado.indice, passo.targetKey);
    }

    final controller = ref.read(tutorialProvider.notifier);
    final tela = MediaQuery.sizeOf(context);
    // Buraco com uma folga em volta do alvo, para o destaque não ficar colado.
    final buraco = _alvo?.inflate(6);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Absorve toques fora do balão: o usuário avança pelos botões.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(painter: _SpotlightPainter(buraco: buraco)),
            ),
          ),
          _BalaoTutorial(
            titulo: passo.titulo,
            descricao: passo.descricao,
            indice: estado.indice,
            total: estado.passos.length,
            isUltimo: estado.isUltimo,
            buraco: buraco,
            tamanhoTela: tela,
            onProximo: controller.proximo,
            onAnterior: estado.indice == 0 ? null : controller.anterior,
            onPular: controller.encerrar,
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({this.buraco});

  final Rect? buraco;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final tela = Offset.zero & size;

    if (buraco == null) {
      canvas.drawRect(tela, scrim);
      return;
    }

    final recorte = RRect.fromRectAndRadius(buraco!, const Radius.circular(12));
    // Escurece tudo menos o alvo, recortando o retângulo do buraco.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(tela),
        Path()..addRRect(recorte),
      ),
      scrim,
    );
    canvas.drawRRect(
      recorte,
      Paint()
        ..color = yellowSecondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.buraco != buraco;
}

class _BalaoTutorial extends StatelessWidget {
  const _BalaoTutorial({
    required this.titulo,
    required this.descricao,
    required this.indice,
    required this.total,
    required this.isUltimo,
    required this.buraco,
    required this.tamanhoTela,
    required this.onProximo,
    required this.onAnterior,
    required this.onPular,
  });

  final String titulo;
  final String descricao;
  final int indice;
  final int total;
  final bool isUltimo;
  final Rect? buraco;
  final Size tamanhoTela;
  final VoidCallback onProximo;
  final VoidCallback? onAnterior;
  final VoidCallback onPular;

  @override
  Widget build(BuildContext context) {
    const larguraMax = 360.0;
    const alturaEstimada = 190.0;
    final largura = tamanhoTela.width < larguraMax
        ? tamanhoTela.width - 32
        : larguraMax;

    double top;
    double left;
    if (buraco == null) {
      top = (tamanhoTela.height - alturaEstimada) / 2;
      left = (tamanhoTela.width - largura) / 2;
    } else {
      // Abaixo do alvo quando cabe; acima caso contrário.
      final abaixo = buraco!.bottom + 16;
      top = abaixo + alturaEstimada < tamanhoTela.height
          ? abaixo
          : buraco!.top - alturaEstimada - 16;
      top = top.clamp(16.0, tamanhoTela.height - alturaEstimada - 16);
      left = (buraco!.center.dx - largura / 2).clamp(
        16.0,
        (tamanhoTela.width - largura - 16).clamp(16.0, double.infinity),
      );
    }

    return Positioned(
      top: top,
      left: left,
      width: largura,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(descricao, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${indice + 1} de $total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (onAnterior != null)
                    TextButton(
                      onPressed: onAnterior,
                      child: const Text('Voltar'),
                    ),
                  if (!isUltimo)
                    TextButton(onPressed: onPular, child: const Text('Pular')),
                  FilledButton(
                    onPressed: onProximo,
                    child: Text(isUltimo ? 'Concluir' : 'Próximo'),
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
