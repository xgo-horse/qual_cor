import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/oklab.dart';

void main() {
  test('branco e preto têm L 1 e 0 sem croma', () {
    final w = Oklab.fromHex('#FFFFFF');
    expect(w.l, closeTo(1.0, 1e-3));
    expect(w.chroma, lessThan(1e-3));
    final k = Oklab.fromHex('#000000');
    expect(k.l, closeTo(0.0, 1e-6));
  });

  test('valores de referência do Ottosson', () {
    // sRGB vermelho puro: L≈0.628, a≈0.225, b≈0.126
    final r = Oklab.fromHex('#FF0000');
    expect(r.l, closeTo(0.628, 2e-3));
    expect(r.a, closeTo(0.225, 2e-3));
    expect(r.b, closeTo(0.126, 2e-3));
  });

  test('ida e volta sRGB → OKLab → sRGB', () {
    for (final hex in ['#123456', '#FF8000', '#00A86B', '#C8A2C8', '#808080']) {
      expect(Oklab.fromHex(hex).toHex(), hex);
    }
  });

  test('matiz e croma', () {
    final b = Oklab.fromHex('#0000FF');
    expect(b.hue, inInclusiveRange(260, 270));
    expect(b.chroma, greaterThan(0.3));
  });

  test('saturação relativa', () {
    expect(Oklab.fromHex('#FF0000').relativeChroma, greaterThan(0.95));
    expect(Oklab.fromHex('#000080').relativeChroma, greaterThan(0.9));
    expect(Oklab.fromHex('#8FBC8F').relativeChroma, lessThan(0.55));
  });
}
