import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import 'describe_text.dart';
import 'style.dart';
import 'themed_texts.dart';

/// Altura de [lines] linhas no [style], já com o tamanho de texto do sistema.
double slotHeight(BuildContext context, TextStyle style, int lines) {
  final effective = DefaultTextStyle.of(context).style.merge(style);
  final painter = TextPainter(
    text: TextSpan(text: List.filled(lines, 'Ág').join('\n'), style: effective),
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

/// Nome grande da família + descrição, num bloco de **altura fixa**.
///
/// O nome nunca termina em reticências: encolhe de 38 até 26 para caber em
/// uma linha; se nem assim couber (tela estreita, texto grande do sistema),
/// quebra em duas linhas e a descrição cede uma das suas. Em qualquer caso
/// o bloco tem a mesma altura, então nada abaixo dele se mexe.
class FamilyHeadline extends StatelessWidget {
  const FamilyHeadline({
    super.key,
    required this.headline,
    required this.description,
  });

  final String headline;
  final String description;

  static const gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final descStyle = Txt.description();
    final oneLine = slotHeight(context, Txt.family(), 1);
    final desc2 = slotHeight(context, descStyle, 2);
    final desc1 = slotHeight(context, descStyle, 1);
    final total = oneLine + gap + desc2;

    return SizedBox(
      height: total,
      child: LayoutBuilder(
        builder: (context, box) {
          final maxW = box.maxWidth;
          // O mesmo estilo efetivo que o Text vai usar (herda do tema).
          final base = DefaultTextStyle.of(context).style;
          double widthAt(double size) {
            final tp = TextPainter(
              text: TextSpan(
                text: headline,
                style: base.merge(Txt.family(size: size)),
              ),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final w = tp.width;
            tp.dispose();
            return w;
          }

          var size = Txt.familySize;
          final full = widthAt(size);
          if (full > maxW) {
            // A largura cresce em proporção ao tamanho da fonte.
            size = (Txt.familySize * maxW / full * 0.98).clamp(
              Txt.familyMinSize,
              Txt.familySize,
            );
          }
          final fits = widthAt(size) <= maxW;

          final Widget name;
          final int descLines;
          if (fits) {
            descLines = 2;
            name = SizedBox(
              height: oneLine,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  headline,
                  key: const Key('family-headline'),
                  style: Txt.family(size: size),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            );
          } else {
            descLines = 1;
            // Duas linhas no tamanho mínimo; se ainda sobrar (texto enorme
            // do sistema), o FittedBox reduz o conjunto em vez de cortar.
            // Sem limite de linhas: o nome nunca leva reticências.
            name = SizedBox(
              height: total - gap - desc1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: maxW,
                  child: Text(
                    headline,
                    key: const Key('family-headline'),
                    style: Txt.family(size: Txt.familyMinSize),
                  ),
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              name,
              const SizedBox(height: gap),
              Slot(description, descStyle, lines: descLines),
            ],
          );
        },
      ),
    );
  }
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
    final hex = texts?.hex;
    final hint = placeholder ?? l10n.tLiveHint;
    final details = texts?.cardDescription ?? '';
    final paintHex = texts?.paint?.paint.hex;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.surface,
        boxShadow: Palette.cardShadow,
        border: Palette.cardBorder,
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
                  ? CustomPaint(painter: _HatchPainter(grim: Palette.grim))
                  : paintHex == null
                  ? ColoredBox(color: Color(0xFF000000 | d.color.toRgbInt()))
                  // Modo Warhammer: em cima a cor medida, embaixo uma faixa
                  // com a tinta, para comparar.
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ColoredBox(
                            color: Color(0xFF000000 | d.color.toRgbInt()),
                          ),
                        ),
                        Container(height: 1, color: Palette.hairline),
                        SizedBox(
                          key: const Key('paint-swatch'),
                          height: 28,
                          child: ColoredBox(
                            color: Color(
                              0xFF000000 |
                                  int.parse(paintHex.substring(1), radix: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                              Slot(
                                texts?.label ?? l10n.tLabelFamily,
                                Txt.label(),
                              ),
                              const SizedBox(height: 2),
                              FamilyHeadline(
                                headline: texts?.headline ?? l10n.emptyFamily,
                                description: d == null ? hint : details,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(
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
                                texts?.footer ?? '',
                                style: Txt.popular(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (hex != null) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              label: texts!.hexLabel,
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
  const _HatchPainter({required this.grim});

  /// Modo Warhammer (as cores vêm da [Palette]).
  final bool grim;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = grim ? Palette.ground : const Color(0xFFF1F0EC),
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
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.grim != grim;
}
