import '../color/area_sampler.dart';
import '../color/citadel_namer.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';
import '../warhammer_mode.dart';

/// Monta as frases do resultado a partir de [ColorDescription], sempre
/// pelos textos do ARB.
///
/// Com o Modo Warhammer ligado, o título, o rótulo, o rodapé, o hex e o
/// texto do leitor de tela passam a ser da tinta Citadel mais próxima
/// ([paint]); a família em português continua, numa linha menor.
class DescriptionTexts {
  DescriptionTexts(this.l10n, this.d, this.warnings, {CitadelNamer? citadel})
    : paint = (citadel ?? warhammer.namer)?.match(d.color);

  final AppLocalizations l10n;
  final ColorDescription d;
  final Set<SampleWarning> warnings;

  /// Tinta Citadel mais próxima (só no Modo Warhammer).
  final CitadelMatch? paint;

  /// Família em minúsculas para frases: "azul", "verde e azul".
  String get _familyLower {
    final second = d.secondFamily;
    final first = l10n.familyName(d.family.name);
    return second == null
        ? first
        : l10n.familyPair(first, l10n.familyName(second.name));
  }

  /// Nível 1: "Azul" ou "Entre verde e azul".
  String get main {
    final second = d.secondFamily;
    if (second != null) {
      return l10n.betweenFamilies(
        l10n.familyName(d.family.name),
        l10n.familyName(second.name),
      );
    }
    return l10n.familyTitle(d.family.name);
  }

  /// Rótulo pequeno do cartão: "FAMÍLIA" ou, entre duas, "ENTRE".
  /// Modo Warhammer: "PIGMENTO · BASE", "LEMBRA · LAYER" ou "ENTRE DOIS
  /// PIGMENTOS".
  String get label {
    final p = paint;
    if (p != null) {
      final range = p.paint.range.toUpperCase();
      if (p.isBetween) return l10n.whLabelBetween;
      return p.isLoose ? l10n.whLabelLembra(range) : l10n.whLabelPigment(range);
    }
    return d.secondFamily == null ? l10n.labelFamily : l10n.labelBetween;
  }

  /// Nome grande do cartão: "Azul" ou "Marrom e vermelho" (o "Entre" fica
  /// no rótulo, para o nome caber). O leitor de tela usa [main].
  /// Modo Warhammer: o nome da tinta.
  String get headline {
    final p = paint;
    if (p != null) {
      return p.isBetween
          ? l10n.whPaintPair(p.paint.name, p.second!.name)
          : p.paint.name;
    }
    final second = d.secondFamily;
    if (second == null) return l10n.familyTitle(d.family.name);
    return l10n.familyPair(
      l10n.familyTitle(d.family.name),
      l10n.familyName(second.name),
    );
  }

  /// Nível 2: "escuro acinzentado, puxando para o verde" (ou vazio).
  String get details {
    final words = <String>[
      if (d.lightness != null) l10n.lightness(d.lightness!.name),
      if (d.saturation != null) l10n.saturation(d.saturation!.name),
    ];
    final parts = <String>[
      if (words.isNotEmpty) words.join(' '),
      if (d.undertone != null) l10n.undertone(d.undertone!.name),
    ];
    return parts.join(', ');
  }

  /// Linha abaixo do título no cartão: os [details] ou, no Modo
  /// Warhammer, a família em português ("Cor: azul, escuro").
  String get cardDescription {
    if (paint == null) return details;
    final more = details;
    return more.isEmpty
        ? l10n.whFamilyLine(_familyLower)
        : l10n.whFamilyLineDetails(_familyLower, more);
  }

  /// Rodapé do cartão: nome popular ou, no Modo Warhammer, a linha da
  /// tinta ("Citadel Base").
  String? get footer {
    final p = paint;
    if (p == null) return d.popularName;
    final second = p.second;
    if (second != null && second.range != p.paint.range) {
      return l10n.whRangePair(p.paint.range, second.range);
    }
    return l10n.whRangeLine(p.paint.range);
  }

  /// Código mostrado e copiado: o da cor medida ou o da tinta.
  String get hex => paint?.paint.hex ?? d.color.toHex();

  /// Leitura do código para o leitor de tela.
  String get hexLabel =>
      paint == null ? l10n.colorCode(hex) : l10n.whPaintCode(hex);

  /// Nível 3: "Parecido com: bordô" / "Lembra: bordô" (ou null).
  String? get popularName {
    final name = d.popularName;
    if (name == null) return null;
    return switch (d.closeness!) {
      NameCloseness.parecido => l10n.nameParecido(name),
      NameCloseness.lembra => l10n.nameLembra(name),
    };
  }

  List<String> get warningTexts => [
    for (final w in SampleWarning.values)
      if (warnings.contains(w))
        switch (w) {
          SampleWarning.lowLight => l10n.warningLowLight,
          SampleWarning.overexposed => l10n.warningOverexposed,
          SampleWarning.highlightRemoved => l10n.warningHighlight,
          SampleWarning.mixedColors => l10n.warningMixed,
        },
  ];

  /// Resumo completo para o leitor de tela (VoiceOver/TalkBack).
  String get accessibleText {
    final p = paint;
    if (p != null) {
      final buf = StringBuffer(
        p.isBetween
            ? l10n.whIdentifiedBetween(p.paint.name, p.second!.name)
            : p.isLoose
            ? l10n.whIdentifiedLembra(p.paint.name, p.paint.range)
            : l10n.whIdentified(p.paint.name, p.paint.range),
      );
      final more = details;
      buf.write(' ');
      buf.write(
        l10n.whColorSummary(
          more.isEmpty ? _familyLower : '$_familyLower, $more',
        ),
      );
      for (final w in warningTexts) {
        buf.write(' $w');
      }
      return buf.toString();
    }
    final buf = StringBuffer(
      details.isEmpty ? '$main.' : l10n.resultSummary(main, details),
    );
    final name = popularName;
    if (name != null) buf.write(' $name.');
    for (final w in warningTexts) {
      buf.write(' $w');
    }
    return buf.toString();
  }
}
