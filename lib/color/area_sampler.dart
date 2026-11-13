import 'oklab.dart';

/// Avisos sobre a qualidade da amostra.
enum SampleWarning { lowLight, overexposed, highlightRemoved, mixedColors }

class SampleResult {
  const SampleResult(this.color, this.warnings, this.pixelCount);

  final Oklab color;
  final Set<SampleWarning> warnings;

  /// Quantos pixels entraram na conta final.
  final int pixelCount;
}

/// Calcula a cor de uma área (nunca de um pixel só).
///
/// Passos: descarta reflexos especulares quando são minoria, separa a
/// área em dois grupos (2-means em OKLab) e, se houver dois grupos
/// grandes e bem diferentes, avisa "cores misturadas" e usa o maior.
class AreaSampler {
  const AreaSampler();

  static const double highlightL = 0.95;
  static const double highlightC = 0.03;
  static const double lowLightL = 0.12;
  static const int clipValue = 250;
  static const double overexposedFraction = 0.25;
  static const double mixedMinorFraction = 0.25;
  static const double mixedDistance = 0.1;

  /// [pixels] são inteiros 0xRRGGBB. Devolve null se a lista estiver vazia.
  SampleResult? sample(List<int> pixels) {
    if (pixels.isEmpty) return null;
    final warnings = <SampleWarning>{};

    var clipped = 0;
    final labs = <Oklab>[];
    for (final p in pixels) {
      final r = (p >> 16) & 0xFF, g = (p >> 8) & 0xFF, b = p & 0xFF;
      if (r >= clipValue || g >= clipValue || b >= clipValue) clipped++;
      labs.add(Oklab.fromRgb(r, g, b));
    }
    if (clipped / pixels.length > overexposedFraction) {
      warnings.add(SampleWarning.overexposed);
    }

    // Reflexos: muito claros e quase sem cor. Só saem se forem minoria;
    // se a área inteira for branca, ela é branca mesmo.
    final kept = labs
        .where((c) => !(c.l > highlightL && c.chroma < highlightC))
        .toList();
    final removed = labs.length - kept.length;
    var working = labs;
    if (removed > 0 && removed < labs.length / 2) {
      working = kept;
      warnings.add(SampleWarning.highlightRemoved);
    }

    var color = _mean(working);
    if (working.length >= 4) {
      final (c1, n1, c2, n2) = _twoMeans(working);
      final minor = (n1 < n2 ? n1 : n2) / working.length;
      if (minor > mixedMinorFraction && c1.distanceTo(c2) > mixedDistance) {
        warnings.add(SampleWarning.mixedColors);
        color = n1 >= n2 ? c1 : c2;
      }
    }

    if (color.l < lowLightL) warnings.add(SampleWarning.lowLight);
    return SampleResult(color, warnings, working.length);
  }

  static Oklab _mean(List<Oklab> list) {
    var l = 0.0, a = 0.0, b = 0.0;
    for (final c in list) {
      l += c.l;
      a += c.a;
      b += c.b;
    }
    final n = list.length.toDouble();
    return Oklab(l / n, a / n, b / n);
  }

  /// 2-means determinístico: começa pelo ponto mais longe da média e
  /// pelo ponto mais longe desse.
  static (Oklab, int, Oklab, int) _twoMeans(List<Oklab> list) {
    final mean = _mean(list);
    Oklab far(Oklab from) {
      var best = list.first;
      var bestD = -1.0;
      for (final c in list) {
        final d = c.distanceTo(from);
        if (d > bestD) {
          bestD = d;
          best = c;
        }
      }
      return best;
    }

    var c1 = far(mean);
    var c2 = far(c1);
    var n1 = 0, n2 = 0;
    for (var iter = 0; iter < 10; iter++) {
      var s1 = const Oklab(0, 0, 0), s2 = const Oklab(0, 0, 0);
      n1 = 0;
      n2 = 0;
      for (final c in list) {
        if (c.distanceTo(c1) <= c.distanceTo(c2)) {
          s1 = s1 + c;
          n1++;
        } else {
          s2 = s2 + c;
          n2++;
        }
      }
      if (n1 == 0 || n2 == 0) break;
      final nc1 = s1 * (1 / n1), nc2 = s2 * (1 / n2);
      final moved = nc1.distanceTo(c1) + nc2.distanceTo(c2);
      c1 = nc1;
      c2 = nc2;
      if (moved < 1e-5) break;
    }
    return (c1, n1, c2, n2);
  }
}
