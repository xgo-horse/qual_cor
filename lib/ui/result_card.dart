import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import 'describe_text.dart';
import 'style.dart';

/// Altura de [lines] linhas no [style], já com o tamanho de texto do sistema.
double slotHeight(BuildContext context, TextStyle style, int lines) {
  final painter = TextPainter(
    text: TextSpan(text: List.filled(lines, 'Ág').join('\n'), style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: lines,
  )..layout();
  final h = painter.height;
  painter.dispose();
  return h;
}

/// Linha de texto com altura reservada: o texto que não cabe termina em
/// reticências, e a altura nunca muda com o conteúdo.
class Slot extends StatelessWidget {
  const Slot(this.text, this.style, {super.key, this.lines = 1});

  final String? text;
  final TextStyle style;
  final int lines;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: slotHeight(context, style, lines),
    child: Align(
      alignment: Alignment.topLeft,
      child: Text(
        text ?? '',
        style: style,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

/// Cartão "cartela de tinta" com **altura fixa**: à esquerda, a cor medida
/// ocupando a altura toda; à direita, rótulo, família (1 linha), descrição
/// (2 linhas) e o rodapé com o nome popular e o código hex com botão de
/// copiar. A troca de cor nunca muda o tamanho do cartão.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.description,
    this.warnings = const {},
    this.placeholder,
  });

  final ColorDescription? description;
  final Set<SampleWarning> warnings;

  /// Texto enquanto não há resultado.
  final String? placeholder;

  static const double swatchWidth = 112;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = description;
    final texts = d == null ? null : DescriptionTexts(l10n, d, warnings);
    final hex = d?.color.toHex();
    final hint = placeholder ?? l10n.liveHint;
    final details = texts?.details ?? '';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Palette.surface,
        boxShadow: Palette.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A cor medida: secundária de propósito (quem é daltônico pode
            // não confiar nela), mas é a "tinta" da cartela.
            SizedBox(
              width: swatchWidth,
              child: d == null
                  ? const CustomPaint(painter: _HatchPainter())
                  : ColoredBox(color: Color(0xFF000000 | d.color.toRgbInt())),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // O leitor de tela anuncia o resultado inteiro de uma
                    // vez (liveRegion), mesmo o que ficou com reticências.
                    Semantics(
                      container: true,
                      liveRegion: true,
                      label: texts?.accessibleText ?? hint,
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Slot(l10n.labelFamily, Txt.label()),
                              const SizedBox(height: 2),
                              Slot(
                                texts?.main ?? l10n.emptyFamily,
                                Txt.family(),
                              ),
                              const SizedBox(height: 4),
                              Slot(
                                d == null ? hint : details,
                                Txt.description(),
                                lines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Palette.hairlineLight,
                    ),
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(
                            child: ExcludeSemantics(
                              child: Text(
                                d?.popularName ?? '',
                                style: Txt.popular(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (hex != null) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              label: l10n.colorCode(hex),
                              child: ExcludeSemantics(
                                child: Text(
                                  hex.substring(1),
                                  style: Txt.mono(size: 12),
                                ),
                              ),
                            ),
                            CopyHexButton(hex: hex),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copia "#RRGGBB" para a área de transferência, com vibração leve, troca o
/// ícone por um "ok" por 1,5 s e mostra um aviso curto.
class CopyHexButton extends StatefulWidget {
  const CopyHexButton({super.key, required this.hex});

  final String hex;

  @override
  State<CopyHexButton> createState() => _CopyHexButtonState();
}

class _CopyHexButtonState extends State<CopyHexButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: widget.hex));
    unawaited(HapticFeedback.lightImpact());
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.codeCopied(widget.hex)),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.copyCode,
      excludeSemantics: true,
      onTap: _copy,
      child: IconButton(
        key: const Key('copy-hex'),
        tooltip: l10n.copyCode,
        onPressed: _copy,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        iconSize: 18,
        color: Palette.text,
        icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
      ),
    );
  }
}

/// Hachurado claro para a "tinta" vazia.
class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F0EC),
    );
    final p = Paint()
      ..color = Palette.hairline
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => false;
}
