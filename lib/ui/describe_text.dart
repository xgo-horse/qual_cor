import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../l10n/generated/app_localizations.dart';

/// Monta as frases do resultado a partir de [ColorDescription], sempre
/// pelos textos do ARB.
class DescriptionTexts {
  DescriptionTexts(this.l10n, this.d, this.warnings);

  final AppLocalizations l10n;
  final ColorDescription d;
  final Set<SampleWarning> warnings;

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
  String get label =>
      d.secondFamily == null ? l10n.labelFamily : l10n.labelBetween;

  /// Nome grande do cartão: "Azul" ou "Marrom e vermelho" (o "Entre" fica
  /// no rótulo, para o nome caber). O leitor de tela usa [main].
  String get headline {
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
