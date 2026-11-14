import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import 'area_slider.dart';
import 'describe_text.dart';
import 'result_card.dart';
import 'style.dart';

/// Metade de baixo das telas de mira e de foto.
///
/// A barra de botões e o controle da área ficam **presos embaixo**, fora de
/// qualquer conteúdo que muda. Acima deles, o cartão (altura fixa) e a linha
/// de avisos (altura reservada); com texto grande do sistema, essa parte
/// rola por dentro em vez de empurrar os botões.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.description,
    required this.warnings,
    required this.areaFraction,
    required this.onAreaChanged,
    required this.bar,
    this.placeholder,
    this.note,
  });

  final ColorDescription? description;
  final Set<SampleWarning> warnings;
  final double areaFraction;
  final ValueChanged<double> onAreaChanged;

  /// Barra de botões da tela ([BottomBar]).
  final Widget bar;

  /// Texto do cartão enquanto não há resultado.
  final String? placeholder;

  /// Mensagem para a linha de avisos quando não há aviso (ex.: dica da
  /// imagem congelada).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = description;
    final warningText = d == null
        ? ''
        : DescriptionTexts(l10n, d, warnings).warningTexts.join(' ');
    final line = warningText.isNotEmpty ? warningText : (note ?? '');
    final style = Txt.warning();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResultCard(
                  description: d,
                  warnings: warnings,
                  placeholder: placeholder,
                ),
                const SizedBox(height: 8),
                // Avisos: uma linha com altura reservada.
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: warningText.isEmpty
                          ? null
                          : Icon(
                              Icons.error_outline,
                              size: 16,
                              color: Palette.muted,
                            ),
                    ),
                    Expanded(child: Slot(line, style)),
                  ],
                ),
              ],
            ),
          ),
        ),
        AreaRow(fraction: areaFraction, onChanged: onAreaChanged),
        bar,
      ],
    );
  }
}

/// Barra inferior: botões chapados de mesma altura (60), ícone em cima e
/// rótulo embaixo, separados por filetes.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.buttons});

  final List<BarButton> buttons;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) {
        children.add(
          VerticalDivider(width: 1, thickness: 1, color: Palette.hairline),
        );
      }
      children.add(
        Expanded(flex: (buttons[i].flex * 10).round(), child: buttons[i]),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Palette.hairline)),
      ),
      child: SizedBox(height: 60, child: Row(children: children)),
    );
  }
}

class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.primary = false,
    this.selected,
    this.flex = 1,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Ação principal: fundo quase preto, texto branco (Modo Warhammer:
  /// vermelho-sangue e pergaminho).
  final bool primary;

  /// Estado de alternância (lanterna), para o leitor de tela.
  final bool? selected;
  final double flex;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = !enabled
        ? Palette.disabled
        : (primary ? Palette.onPrimary : Palette.text);
    final button = Material(
      color: primary
          ? (enabled
                ? Palette.primary
                : (Palette.grim ? Palette.hairlineLight : Palette.hairline))
          : Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Txt.sans(
                size: 14,
                weight: primary ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      toggled: selected,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: tooltip != null,
      child: button,
    );
  }
}
