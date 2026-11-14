import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/citadel_namer.dart';
import 'package:qual_cor/color/oklab.dart';

void main() {
  // O JSON real que vai no app.
  final namer = CitadelNamer.fromJson(
    File(CitadelNamer.asset).readAsStringSync(),
  );

  test('carrega o JSON real e junta tintas de mesmo hex', () {
    expect(namer.paints.length, greaterThan(200));
    final hexes = namer.paints.map((p) => p.hex).toSet();
    expect(hexes.length, namer.paints.length);
    expect(
      namer.paints.map((p) => p.range).toSet(),
      containsAll(['Base', 'Layer', 'Shade', 'Contrast']),
    );
  });

  test('OKLCH do JSON vira OKLab igual ao calculado do hex', () {
    for (final p in namer.paints) {
      expect(
        p.lab.distanceTo(Oklab.fromHex(p.hex)),
        lessThan(0.002),
        reason: p.toString(),
      );
    }
  });

  test('#000000 é Abaddon Black (não o spray de mesmo hex)', () {
    final m = namer.match(Oklab.fromHex('#000000'));
    expect(m.paint.name, 'Abaddon Black');
    expect(m.paint.range, 'Base');
    expect(m.isBetween, isFalse);
    expect(m.isLoose, isFalse);
  });

  test('o hex de Mephiston Red volta Mephiston Red', () {
    final hex = namer.paints.firstWhere((p) => p.name == 'Mephiston Red').hex;
    final m = namer.match(Oklab.fromHex(hex));
    expect(m.paint.name, 'Mephiston Red');
    expect(m.distance, lessThan(0.002));
    expect(m.isBetween, isFalse);
  });

  test('toda tinta é achada pelo próprio hex', () {
    for (final p in namer.paints) {
      expect(
        namer.match(Oklab.fromHex(p.hex)).paint.name,
        p.name,
        reason: p.toString(),
      );
    }
  });

  test('cor longe de todas as tintas só "lembra"', () {
    // Verde-limão saturado ao máximo: nenhuma tinta chega perto.
    final m = namer.match(Oklab.fromHex('#00FF00'));
    expect(m.isLoose, isTrue);
    expect(m.distance, greaterThan(CitadelNamer.lembraFrom));
    expect(m.isBetween, isFalse);
  });

  group('lista pequena', () {
    CitadelPaint paint(String name, String hex) => CitadelPaint(
      name: name,
      range: 'Base',
      hex: hex,
      lab: Oklab.fromHex(hex),
    );
    final a = paint('A', '#800000');
    final b = paint('B', '#8C0000');
    final small = CitadelNamer([a, b, paint('A2', '#800000')]);

    test('hex repetido fica só a primeira', () {
      expect(small.paints.map((p) => p.name), ['A', 'B']);
    });

    test('no meio das duas: entre X e Y', () {
      final mid = a.lab.lerp(b.lab, 0.5);
      final m = small.match(mid);
      expect(m.isBetween, isTrue);
      expect({m.paint.name, m.second!.name}, {'A', 'B'});
    });

    test('perto de uma: só ela', () {
      final m = small.match(a.lab.lerp(b.lab, 0.1));
      expect(m.paint.name, 'A');
      expect(m.isBetween, isFalse);
    });

    test('lista vazia é erro', () {
      expect(() => CitadelNamer([]), throwsArgumentError);
    });
  });
}
