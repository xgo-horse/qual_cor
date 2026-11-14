import 'dart:convert';
import 'dart:math' as math;

import 'oklab.dart';

/// Uma tinta Citadel (Games Workshop) do conjunto em
/// `assets/data/citadel_paints.json`. As cores são aproximações da
/// comunidade, não valores oficiais.
class CitadelPaint {
  const CitadelPaint({
    required this.name,
    required this.range,
    required this.hex,
    required this.lab,
    this.metallic = false,
  });

  /// Lê uma entrada do JSON (`name`, `range`, `hex`, `oklch_l/c/h`).
  /// O OKLCH vira OKLab aqui, uma vez só.
  factory CitadelPaint.fromJson(Map<String, dynamic> j) {
    final l = (j['oklch_l'] as num).toDouble();
    final c = (j['oklch_c'] as num).toDouble();
    final h = (j['oklch_h'] as num).toDouble() * math.pi / 180;
    return CitadelPaint(
      name: j['name'] as String,
      range: j['range'] as String,
      hex: (j['hex'] as String).toUpperCase(),
      lab: Oklab(l, c * math.cos(h), c * math.sin(h)),
      metallic: j['metallic'] as bool? ?? false,
    );
  }

  final String name;

  /// Linha da tinta: Base, Layer, Shade, Contrast, Dry, Air, Glaze, Spray.
  final String range;

  /// "#RRGGBB".
  final String hex;
  final Oklab lab;
  final bool metallic;

  @override
  String toString() => '$name ($range, $hex)';
}

/// Resultado de [CitadelNamer.match], sem nenhum texto (a interface monta
/// as frases pelos ARB, como no ColorNamer).
class CitadelMatch {
  const CitadelMatch({
    required this.paint,
    required this.distance,
    this.second,
    this.secondDistance,
  });

  /// Tinta mais próxima.
  final CitadelPaint paint;

  /// Distância em OKLab até [paint].
  final double distance;

  /// Segunda tinta, quando está quase empatada ("entre X e Y").
  final CitadelPaint? second;
  final double? secondDistance;

  bool get isBetween => second != null;

  /// Longe de qualquer tinta: o texto diz "lembra".
  bool get isLoose => distance > CitadelNamer.lembraFrom;

  /// Muda só quando o texto mostrado muda.
  String get textKey => '${paint.name}|${second?.name}|$isLoose';
}

/// Acha a tinta Citadel mais próxima de uma cor, pela distância Euclidiana
/// em OKLab. Independente do [ColorNamer]: o modo Warhammer só troca o
/// título; a família em português continua vindo do ColorNamer.
class CitadelNamer {
  /// Tintas com o mesmo hex (ex.: Abaddon Black e o spray Chaos Black)
  /// viram uma só, a primeira da lista; senão toda cor delas cairia em
  /// "entre X e Y" com a mesma cor dos dois lados.
  CitadelNamer(Iterable<CitadelPaint> paints)
    : paints = List.unmodifiable(_uniqueByHex(paints)) {
    if (this.paints.isEmpty) {
      throw ArgumentError.value(paints, 'paints', 'lista vazia');
    }
  }

  /// Lê o conteúdo de `assets/data/citadel_paints.json`.
  factory CitadelNamer.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final list = (data['paints'] as List).cast<Map<String, dynamic>>();
    return CitadelNamer(list.map(CitadelPaint.fromJson));
  }

  static const asset = 'assets/data/citadel_paints.json';

  final List<CitadelPaint> paints;

  /// Acima desta distância a tinta só "lembra" a cor.
  static const double lembraFrom = 0.06;

  /// Se a segunda tinta estiver a menos disto além da primeira, o
  /// resultado vira "entre X e Y" (só quando a primeira não está longe).
  static const double tieMargin = 0.006;

  /// Perto assim de uma tinta, ela ganha sozinha mesmo com outra quase
  /// empatada (a cor é praticamente a dela).
  static const double exactMax = 0.004;

  CitadelMatch match(Oklab c) {
    CitadelPaint? best, second;
    var d1 = double.infinity, d2 = double.infinity;
    for (final p in paints) {
      final d = c.distanceTo(p.lab);
      if (d < d1) {
        second = best;
        d2 = d1;
        best = p;
        d1 = d;
      } else if (d < d2) {
        second = p;
        d2 = d;
      }
    }
    // Longe de tudo ("lembra"), um empate não diz nada: fica só a primeira.
    final tie =
        second != null &&
        d1 > exactMax &&
        d1 <= lembraFrom &&
        d2 - d1 < tieMargin;
    return CitadelMatch(
      paint: best!,
      distance: d1,
      second: tie ? second : null,
      secondDistance: tie ? d2 : null,
    );
  }

  static List<CitadelPaint> _uniqueByHex(Iterable<CitadelPaint> paints) {
    final seen = <String>{};
    return [
      for (final p in paints)
        if (seen.add(p.hex)) p,
    ];
  }
}
