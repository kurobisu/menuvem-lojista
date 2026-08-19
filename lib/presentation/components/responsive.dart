import 'package:flutter/material.dart';

const double kCompactBreakpoint = 700;
const double kFormMaxWidth = 480;
const double kContentMaxWidth = 720;
const double kDashboardMaxWidth = 960;
const double kFormDialogWidth = 520;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kCompactBreakpoint;

/// Limita a largura do conteúdo e centraliza — em janelas estreitas
/// (largura menor que [maxWidth]) não tem efeito nenhum, o ConstrainedBox
/// se ajusta à largura disponível.
class MaxWidthCenter extends StatelessWidget {
  const MaxWidthCenter({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Abre um formulário como bottom sheet em janelas estreitas (comportamento
/// mobile de sempre) ou como dialog centralizado em janelas largas — mesma
/// assinatura de `showModalBottomSheet`, mesmo `Future<T?>` de retorno.
Future<T?> showResponsiveFormSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (isWideScreen(context)) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kFormDialogWidth,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: builder(ctx),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}
