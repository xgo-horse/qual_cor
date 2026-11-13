import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import 'describe_text.dart';
import 'speech.dart';

/// Cartão com o resultado: família em letras bem grandes, descrição,
/// nome popular, avisos, amostra pequena (secundária) e botão "Falar".
class ResultCard extends StatefulWidget {
  const ResultCard({
    super.key,
    required this.description,
    this.warnings = const {},
    this.onSpeak,
  });

  final ColorDescription description;
  final Set<SampleWarning> warnings;

  /// Por padrão fala com [Speech]; os testes trocam por um callback.
  final void Function(String text)? onSpeak;

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _showHex = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texts = DescriptionTexts(l10n, widget.description, widget.warnings);
    final theme = Theme.of(context);
    final details = texts.details;
    final name = texts.popularName;
    final warnings = texts.warningTexts;
    final hex = widget.description.color.toHex();

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // O leitor de tela anuncia o resultado inteiro de uma vez
            // (liveRegion) em vez de cada linha separada.
            Semantics(
              container: true,
              liveRegion: true,
              label: texts.spoken,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            texts.main,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _Swatch(
                          color: Color(
                            0xFF000000 | widget.description.color.toRgbInt(),
                          ),
                        ),
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(details, style: theme.textTheme.titleMedium),
                    ],
                    if (name != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    for (final w in warnings)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(w, style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    if (_showHex) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.hexCode(hex),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final speak = widget.onSpeak ?? Speech.instance.speak;
                      speak(texts.spoken);
                    },
                    icon: const Icon(Icons.volume_up),
                    label: Text(l10n.speak),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () => setState(() => _showHex = !_showHex),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      _showHex ? l10n.hideHex : l10n.showHex,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
