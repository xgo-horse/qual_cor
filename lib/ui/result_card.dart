import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import 'describe_text.dart';

/// Cartão com o resultado, com **altura fixa**: cada linha tem um espaço
/// reservado (família 1 linha, descrição 2, nome popular 1, avisos 2), com
/// reticências no que não couber. Assim a troca de cor nunca muda o tamanho
/// do cartão nem empurra os botões.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.description,
    this.warnings = const {},
    this.showHex = false,
    this.placeholder,
  });

  final ColorDescription? description;
  final Set<SampleWarning> warnings;
  final bool showHex;

  /// Texto mostrado enquanto não há resultado.
  final String? placeholder;

  /// Altura de [lines] linhas no [style], já com o tamanho de texto do
  /// sistema.
  static double slotHeight(BuildContext context, TextStyle style, int lines) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = description;
    final texts = d == null ? null : DescriptionTexts(l10n, d, warnings);

    final mainStyle = theme.textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w800,
    );
    final detailStyle = theme.textTheme.titleMedium!;
    final nameStyle = theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.primary,
    );
    final warnStyle = theme.textTheme.bodyMedium!;

    Widget slot(String? text, TextStyle style, int lines) => SizedBox(
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

    final warningText = texts?.warningTexts.join(' ') ?? '';
    final hex = d?.color.toHex();

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        // O leitor de tela anuncia o resultado inteiro de uma vez
        // (liveRegion), mesmo o que ficou cortado com reticências.
        child: Semantics(
          container: true,
          liveRegion: true,
          label: texts?.accessibleText ?? placeholder ?? l10n.liveHint,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: slot(
                        texts?.main ?? placeholder ?? l10n.liveHint,
                        d == null ? detailStyle : mainStyle,
                        1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Swatch(
                      color: d == null
                          ? Colors.transparent
                          : Color(0xFF000000 | d.color.toRgbInt()),
                    ),
                  ],
                ),
                slot(texts?.details, detailStyle, 2),
                Row(
                  children: [
                    Expanded(child: slot(texts?.popularName, nameStyle, 1)),
                    if (showHex && hex != null) ...[
                      const SizedBox(width: 8),
                      Text(l10n.hexCode(hex), style: warnStyle, maxLines: 1),
                    ],
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: warningText.isEmpty
                          ? null
                          : Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                    Expanded(child: slot(warningText, warnStyle, 2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).swatchLabel,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
