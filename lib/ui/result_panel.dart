import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import 'area_slider.dart';
import 'result_card.dart';

/// Metade de baixo das telas de mira e de foto.
///
/// Os controles (tamanho da área e botões) ficam **presos embaixo**, fora
/// de qualquer conteúdo que muda. O resultado fica no espaço acima deles:
/// com o texto no tamanho normal ele cabe inteiro (altura fixa); com texto
/// grande do sistema, rola por dentro em vez de empurrar os botões.
class ResultPanel extends StatefulWidget {
  const ResultPanel({
    super.key,
    required this.description,
    required this.warnings,
    required this.areaFraction,
    required this.onAreaChanged,
    this.actions = const [],
    this.placeholder,
  });

  final ColorDescription? description;
  final Set<SampleWarning> warnings;
  final double areaFraction;
  final ValueChanged<double> onAreaChanged;

  /// Botões extras da tela (ex.: Congelar, Lanterna), antes de "Código".
  final List<Widget> actions;

  /// Texto do cartão enquanto não há resultado.
  final String? placeholder;

  @override
  State<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<ResultPanel> {
  bool _showHex = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ResultCard(
              description: widget.description,
              warnings: widget.warnings,
              showHex: _showHex,
              placeholder: widget.placeholder,
            ),
          ),
        ),
        AreaSlider(
          fraction: widget.areaFraction,
          onChanged: widget.onAreaChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              for (final a in widget.actions) ...[
                Expanded(child: a),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ControlButton(
                  key: const Key('hex-toggle'),
                  icon: Icons.tag,
                  label: l10n.hexToggle,
                  tooltip: _showHex ? l10n.hideHex : l10n.showHex,
                  selected: _showHex,
                  onPressed: widget.description == null
                      ? null
                      : () => setState(() => _showHex = !_showHex),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão compacto de largura flexível: rótulo curto em 1 linha (com
/// reticências se faltar espaço), dica e estado para o leitor de tela.
class ControlButton extends StatelessWidget {
  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.selected,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = selected ?? false;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        toggled: selected,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            backgroundColor: on ? theme.colorScheme.primary : null,
            foregroundColor: on ? theme.colorScheme.onPrimary : Colors.white,
          ),
          icon: Icon(icon, size: 20),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
