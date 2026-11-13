import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';

/// Controle do tamanho da área amostrada, em % do lado menor da imagem.
class AreaSlider extends StatelessWidget {
  const AreaSlider({
    super.key,
    required this.fraction,
    required this.onChanged,
  });

  static const double min = 0.01;
  static const double max = 0.10;

  final double fraction;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(l10n.areaSize, style: Theme.of(context).textTheme.bodyLarge),
          Expanded(
            child: Slider(
              value: fraction.clamp(min, max),
              min: min,
              max: max,
              divisions: 9,
              label: l10n.areaSizeValue(percent),
              semanticFormatterCallback: (_) => l10n.areaSizeValue(percent),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
