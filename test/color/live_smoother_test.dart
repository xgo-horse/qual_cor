import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/color_names_pt.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/live_smoother.dart';
import 'package:qual_cor/color/oklab.dart';

void main() {
  final namer = ColorNamer();

  test('primeiro quadro aparece na hora', () {
    final s = LiveSmoother(namer);
    expect(s.add(Oklab.fromHex('#FF0000')), isTrue);
    expect(s.shown!.family, ColorFamily.vermelho);
  });

  test('objeto novo (mudança grande) troca no quadro seguinte', () {
    for (final pair in [
      ['#FF0000', '#0000FF'],
      ['#008000', '#8B4513'],
      ['#FFFF00', '#FF8000'],
      ['#808080', '#000080'],
    ]) {
      final s = LiveSmoother(namer)..add(Oklab.fromHex(pair[0]));
      s.add(Oklab.fromHex(pair[1]));
      expect(
        s.shown!.textKey,
        namer.describe(Oklab.fromHex(pair[1])).textKey,
        reason: '${pair[0]} -> ${pair[1]}',
      );
    }
  });

  test('ruído pequeno não faz o texto piscar', () {
    final s = LiveSmoother(namer);
    final base = Oklab.fromHex('#3366CC');
    s.add(base);
    final key = s.shown!.textKey;
    for (var i = 0; i < 40; i++) {
      final e = (i.isEven ? 1 : -1) * 0.012;
      s.add(Oklab(base.l + e, base.a - e, base.b + e));
      expect(s.shown!.textKey, key);
    }
  });

  test('fronteira entre dois nomes: precisa de 2 quadros seguidos', () {
    final s = LiveSmoother(namer, alpha: 1);
    // Duas cores próximas (abaixo do limiar de salto) com textos diferentes.
    final a = Oklab.fromHex('#808080'); // cinza
    final b = Oklab(a.l + 0.05, a.a, a.b); // cinza claro?
    final ka = namer.describe(a).textKey, kb = namer.describe(b).textKey;
    expect(a.distanceTo(b), lessThan(s.jumpDistance));
    expect(ka, isNot(kb));
    s.add(a);
    s.add(b); // 1º quadro com o texto novo: ainda não troca
    expect(s.shown!.textKey, ka);
    s.add(b); // 2º seguido: troca
    expect(s.shown!.textKey, kb);
  });

  test('reset volta ao estado inicial', () {
    final s = LiveSmoother(namer)..add(Oklab.fromHex('#FF0000'));
    s.reset();
    expect(s.shown, isNull);
  });
}
