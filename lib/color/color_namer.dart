import 'dart:math' as math;

import 'color_names_pt.dart';
import 'oklab.dart';

/// Nível 2: claridade em relação ao valor típico da família.
enum Lightness { muitoClaro, claro, escuro, muitoEscuro }

/// Nível 2: saturação em relação ao valor típico da família.
enum Saturation { acinzentado, suave, vivo }

/// Nível 3: o quanto o nome popular está perto da cor medida.
enum NameCloseness { parecido, lembra }

/// Resultado da nomeação, sem nenhum texto: a interface monta as frases
/// com os ARB a partir destes valores.
class ColorDescription {
  const ColorDescription({
    required this.color,
    required this.family,
    this.secondFamily,
    this.lightness,
    this.saturation,
    this.undertone,
    this.popularName,
    this.closeness,
    required this.familyScores,
  });

  final Oklab color;

  /// Família principal (nível 1).
  final ColorFamily family;

  /// Preenchida quando a cor fica entre duas famílias ("entre X e Y").
  final ColorFamily? secondFamily;

  final Lightness? lightness;
  final Saturation? saturation;

  /// "puxando para o …"
  final ColorFamily? undertone;

  /// Nome popular mais próximo, só quando está perto o bastante.
  final String? popularName;
  final NameCloseness? closeness;

  /// Pontuação normalizada (soma 1) de cada família no k-NN.
  final Map<ColorFamily, double> familyScores;

  bool get isAmbiguous => secondFamily != null;

  /// Chave que muda só quando o texto mostrado muda (útil para a mira ao
  /// vivo não ficar trocando o anúncio do leitor de tela à toa).
  String get textKey =>
      '$family|$secondFamily|$lightness|$saturation|$undertone|$popularName|$closeness';
}

/// Decide o nome de uma cor em três níveis. Ver README para os motivos.
class ColorNamer {
  ColorNamer({List<NamedColor>? names, this.k = 7})
    : names = names ?? colorNamesPt {
    // O valor "típico" de cada família é o da cor canônica (a entrada com
    // o mesmo nome da família, como "vermelho" = #FF0000). Assim o
    // vermelho puro não vira "vermelho claro" só porque a lista tem
    // muitos vermelhos escuros (bordô, vinho...). Sem canônica, usa a média.
    for (final f in ColorFamily.values) {
      final members = this.names.where((n) => n.family == f).toList();
      if (members.isEmpty) continue;
      final canonical = members.where((n) => n.name == f.name).firstOrNull;
      if (canonical != null) {
        _typicalL[f] = canonical.lab.l;
        _typicalC[f] = canonical.lab.chroma;
      } else {
        _typicalL[f] =
            members.map((n) => n.lab.l).reduce((a, b) => a + b) /
            members.length;
        _typicalC[f] =
            members.map((n) => n.lab.chroma).reduce((a, b) => a + b) /
            members.length;
      }
    }
  }

  final List<NamedColor> names;
  final int k;
  final Map<ColorFamily, double> _typicalL = {};
  final Map<ColorFamily, double> _typicalC = {};

  /// Abaixo deste croma a cor é tratada como neutra (preto, cinza, branco).
  static const double achromaticChroma = 0.02;

  /// Se a segunda família tiver pelo menos esta fração da pontuação da
  /// primeira, o resultado vira "entre X e Y".
  static const double ambiguityRatio = 0.75;

  /// Distâncias (OKLab) para o nível 3.
  static const double parecidoMax = 0.035;
  static const double lembraMax = 0.075;

  double typicalLightness(ColorFamily f) => _typicalL[f]!;
  double typicalChroma(ColorFamily f) => _typicalC[f]!;

  ColorDescription describe(Oklab c) {
    final chroma = c.chroma;

    // Nível 1: família.
    final Map<ColorFamily, double> scores;
    if (chroma < achromaticChroma) {
      scores = {_achromaticByLightness(c.l): 1.0};
    } else {
      scores = _knnScores(c, names);
    }
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final family = ranked.first.key;
    ColorFamily? second;
    if (ranked.length > 1 &&
        ranked[1].value >= ranked.first.value * ambiguityRatio) {
      second = ranked[1].key;
    }

    // Nível 2: claridade e saturação relativas à família.
    Lightness? lightness;
    Saturation? saturation;
    if (family != ColorFamily.preto && family != ColorFamily.branco) {
      final dl = c.l - _typicalL[family]!;
      if (dl <= -0.24) {
        lightness = Lightness.muitoEscuro;
      } else if (dl <= -0.09) {
        lightness = Lightness.escuro;
      } else if (dl >= 0.24) {
        lightness = Lightness.muitoClaro;
      } else if (dl >= 0.09) {
        lightness = Lightness.claro;
      }
    }
    if (!family.isAchromatic) {
      // Saturação relativa ao máximo que o sRGB permite nesta claridade e
      // matiz. Comparar com o croma bruto da cor canônica faria o
      // azul-marinho (escuro, mas no limite da saturação) parecer "suave".
      final rel = c.relativeChroma;
      if (rel < 0.3) {
        saturation = Saturation.acinzentado;
      } else if (rel < 0.55) {
        saturation = Saturation.suave;
      } else if (rel > 0.9 &&
          chroma > 0.15 &&
          chroma > 0.8 * _typicalC[family]!) {
        // "Vivo" só para cores intensas de verdade: perto do branco ou do
        // preto qualquer cor bate no limite do sRGB com pouco croma.
        saturation = Saturation.vivo;
      }
    }

    // Subtom: "puxando para o …".
    ColorFamily? undertone;
    if (second == null) {
      if (family.isAchromatic) {
        if (chroma > achromaticChroma) {
          final chromatic = names.where((n) => !n.family.isAchromatic);
          undertone = _best(_knnScores(c, chromatic, byHueOnly: true));
        }
      } else {
        for (final e in ranked.skip(1)) {
          if (e.key.isAchromatic) continue;
          if (e.value >= ranked.first.value * 0.2) undertone = e.key;
          break;
        }
      }
    }

    // Nível 3: nome popular mais próximo.
    NamedColor? nearest;
    var nearestD = double.infinity;
    for (final n in names) {
      final d = c.distanceTo(n.lab);
      if (d < nearestD) {
        nearestD = d;
        nearest = n;
      }
    }
    NameCloseness? closeness;
    if (nearestD <= parecidoMax) {
      closeness = NameCloseness.parecido;
    } else if (nearestD <= lembraMax) {
      closeness = NameCloseness.lembra;
    }

    return ColorDescription(
      color: c,
      family: family,
      secondFamily: second,
      lightness: lightness,
      saturation: saturation,
      undertone: undertone,
      popularName: closeness == null ? null : nearest!.name,
      closeness: closeness,
      familyScores: scores,
    );
  }

  static ColorFamily _achromaticByLightness(double l) {
    if (l < 0.25) return ColorFamily.preto;
    if (l > 0.94) return ColorFamily.branco;
    return ColorFamily.cinza;
  }

  static ColorFamily? _best(Map<ColorFamily, double> scores) {
    ColorFamily? best;
    var bestV = -1.0;
    scores.forEach((f, v) {
      if (v > bestV) {
        bestV = v;
        best = f;
      }
    });
    return best;
  }

  /// k-NN ponderado pelo inverso da distância. Devolve pontuações que
  /// somam 1.
  Map<ColorFamily, double> _knnScores(
    Oklab c,
    Iterable<NamedColor> pool, {
    bool byHueOnly = false,
  }) {
    final list = <(double, ColorFamily)>[];
    for (final n in pool) {
      final double d;
      if (byHueOnly) {
        // Só o ângulo do matiz importa (para o subtom dos cinzas).
        var dh = (c.hue - n.lab.hue).abs();
        if (dh > 180) dh = 360 - dh;
        d = dh / 180;
      } else {
        d = c.distanceTo(n.lab);
      }
      list.add((d, n.family));
    }
    list.sort((x, y) => x.$1.compareTo(y.$1));
    final scores = <ColorFamily, double>{};
    var total = 0.0;
    for (final (d, f) in list.take(math.min(k, list.length))) {
      final w = 1 / (d + 0.02);
      scores[f] = (scores[f] ?? 0) + w;
      total += w;
    }
    return scores.map((f, v) => MapEntry(f, v / total));
  }
}
