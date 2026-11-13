import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import 'style.dart';

/// Moldura da câmera/foto: cantos quase retos, filete fino; congelada, o
/// filete engrossa e aparece a etiqueta "CONGELADO".
class CameraFrame extends StatelessWidget {
  const CameraFrame({
    super.key,
    required this.child,
    this.frozen = false,
    this.frozenLabel,
    this.trailing,
    this.background = const Color(0xFF2A2A27),
  });

  final Widget child;
  final bool frozen;
  final String? frozenLabel;
  final Widget? trailing;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: frozen ? Palette.text : const Color(0x26000000),
          width: frozen ? 2 : 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (frozen && frozenLabel != null)
            Positioned(
              left: 10,
              top: 10,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Palette.surface),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Text(
                    frozenLabel!,
                    style: Txt.label(color: Palette.text),
                  ),
                ),
              ),
            ),
          if (trailing != null) Positioned(right: 4, top: 4, child: trailing!),
        ],
      ),
    );
  }
}

/// Botão "Sobre o app": círculo escuro translúcido para aparecer sobre a
/// imagem.
class InfoButton extends StatelessWidget {
  const InfoButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('about'),
      tooltip: AppLocalizations.of(context).about,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      icon: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0x73000000),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.info_outline, size: 18, color: Colors.white),
      ),
    );
  }
}

/// Mensagem dentro da moldura (sem câmera, sem permissão): ícone, texto e
/// uma ação.
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Txt.sans(size: 15, color: Colors.white),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: const RoundedRectangleBorder(),
                  minimumSize: const Size(48, 44),
                ),
                child: Text(
                  actionLabel!,
                  style: Txt.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mira fina: círculo branco de 1,5 px do tamanho da área lida e quatro
/// traços curtos (2×12) em cima, embaixo e dos lados, com uma sombra leve
/// para aparecer também sobre fundos claros.
void paintCrosshair(Canvas canvas, Offset c, double radius) {
  final shadow = Paint()
    ..color = const Color(0x59000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  final circle = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  canvas.drawCircle(c, radius, shadow);
  canvas.drawCircle(c, radius, circle);
  const gap = 6.0, len = 12.0;
  final ticks = [
    Rect.fromCenter(
      center: c.translate(0, -radius - gap - len / 2),
      width: 2,
      height: len,
    ),
    Rect.fromCenter(
      center: c.translate(0, radius + gap + len / 2),
      width: 2,
      height: len,
    ),
    Rect.fromCenter(
      center: c.translate(-radius - gap - len / 2, 0),
      width: len,
      height: 2,
    ),
    Rect.fromCenter(
      center: c.translate(radius + gap + len / 2, 0),
      width: len,
      height: 2,
    ),
  ];
  final shadowFill = Paint()
    ..color = const Color(0x59000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  final fill = Paint()..color = Colors.white;
  for (final t in ticks) {
    canvas.drawRect(t.inflate(0.5), shadowFill);
    canvas.drawRect(t, fill);
  }
}
