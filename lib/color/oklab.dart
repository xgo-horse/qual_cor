import 'dart:math' as math;

/// Uma cor no espaço OKLab (Björn Ottosson, 2020).
///
/// [l] vai de 0 (preto) a 1 (branco); [a] e [b] ficam aproximadamente
/// entre -0.4 e 0.4. Distâncias euclidianas neste espaço acompanham bem
/// a diferença percebida entre cores.
class Oklab {
  const Oklab(this.l, this.a, this.b);

  final double l;
  final double a;
  final double b;

  /// Croma (saturação percebida) do OKLCH.
  double get chroma => math.sqrt(a * a + b * b);

  /// Matiz do OKLCH em graus, de 0 a 360.
  double get hue {
    final h = math.atan2(b, a) * 180 / math.pi;
    return h < 0 ? h + 360 : h;
  }

  double distanceTo(Oklab o) {
    final dl = l - o.l, da = a - o.a, db = b - o.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  Oklab operator +(Oklab o) => Oklab(l + o.l, a + o.a, b + o.b);
  Oklab operator *(double k) => Oklab(l * k, a * k, b * k);

  /// Interpolação linear: `t = 0` devolve esta cor, `t = 1` devolve [o].
  Oklab lerp(Oklab o, double t) =>
      Oklab(l + (o.l - l) * t, a + (o.a - a) * t, b + (o.b - b) * t);

  /// Converte de sRGB (canais 0–255).
  factory Oklab.fromRgb(int r, int g, int b) {
    final lr = _srgbToLinear[r & 0xFF];
    final lg = _srgbToLinear[g & 0xFF];
    final lb = _srgbToLinear[b & 0xFF];
    final l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb;
    final m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb;
    final s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb;
    final l_ = _cbrt(l), m_ = _cbrt(m), s_ = _cbrt(s);
    return Oklab(
      0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
      1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
      0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    );
  }

  /// Converte de um inteiro 0xRRGGBB.
  factory Oklab.fromRgbInt(int rgb) =>
      Oklab.fromRgb((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);

  /// Converte de um texto como "#8B4513" ou "8B4513".
  factory Oklab.fromHex(String hex) =>
      Oklab.fromRgbInt(int.parse(hex.replaceFirst('#', ''), radix: 16));

  /// Volta para sRGB 0xRRGGBB, cortando valores fora da gama.
  int toRgbInt() {
    final (r, g, bl) = _toLinear();
    return (_linearToSrgb(r) << 16) |
        (_linearToSrgb(g) << 8) |
        _linearToSrgb(bl);
  }

  /// Se a cor cabe no sRGB (com uma pequena tolerância).
  bool get isInGamut {
    final (r, g, bl) = _toLinear();
    const e = 1e-4;
    return r >= -e &&
        r <= 1 + e &&
        g >= -e &&
        g <= 1 + e &&
        bl >= -e &&
        bl <= 1 + e;
  }

  /// Maior croma que cabe no sRGB com esta claridade e este matiz.
  double get maxChromaInGamut {
    final h = math.atan2(b, a);
    final ch = math.cos(h), sh = math.sin(h);
    var lo = 0.0, hi = 0.5;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (Oklab(l, mid * ch, mid * sh).isInGamut) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Saturação relativa: croma dividido pelo máximo possível (0 a 1).
  double get relativeChroma {
    final max = maxChromaInGamut;
    return max <= 1e-6 ? 0 : (chroma / max).clamp(0.0, 1.0);
  }

  (double, double, double) _toLinear() {
    final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    final s_ = l - 0.0894841775 * a - 1.2914855480 * b;
    final ll = l_ * l_ * l_, mm = m_ * m_ * m_, ss = s_ * s_ * s_;
    return (
      4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss,
      -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss,
      -0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss,
    );
  }

  /// Código hexadecimal "#RRGGBB".
  String toHex() =>
      '#${toRgbInt().toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  String toString() =>
      'Oklab(${l.toStringAsFixed(3)}, ${a.toStringAsFixed(3)}, ${b.toStringAsFixed(3)})';
}

final List<double> _srgbToLinear = List<double>.generate(256, (i) {
  final c = i / 255.0;
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}, growable: false);

int _linearToSrgb(double x) {
  final c = x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
  return (c * 255).round().clamp(0, 255);
}

double _cbrt(double x) =>
    x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();
