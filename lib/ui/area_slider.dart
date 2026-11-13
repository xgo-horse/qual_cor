import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import 'style.dart';

/// Controle do tamanho da área, em % do lado menor da imagem.
class AreaRow extends StatelessWidget {
  const AreaRow({super.key, required this.fraction, required this.onChanged});

  static const double min = 0.01;
  static const double max = 0.10;

  final double fraction;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
      child: Row(
        children: [
          ExcludeSemantics(child: Text(l10n.labelArea, style: Txt.label())),
          Expanded(
            child: Slider(
              value: fraction.clamp(min, max),
              min: min,
              max: max,
              divisions: 9,
              label: '$percent%',
              semanticFormatterCallback: (_) => l10n.areaSizeValue(percent),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
