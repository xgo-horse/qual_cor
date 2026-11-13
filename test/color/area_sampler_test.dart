import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/area_sampler.dart';
import 'package:qual_cor/color/oklab.dart';
import 'package:qual_cor/color/pixel_area.dart';

void main() {
  const sampler = AreaSampler();

  test('lista vazia devolve null', () {
    expect(sampler.sample([]), isNull);
  });

  test('área uniforme: cor exata e sem avisos', () {
    final r = sampler.sample(List.filled(100, 0x3366CC))!;
    expect(r.color.toHex(), '#3366CC');
    expect(r.warnings, isEmpty);
  });

  test('ruído é amortecido pela média', () {
    final px = <int>[];
    for (var i = 0; i < 100; i++) {
      px.add(i.isEven ? 0x7A0000 : 0x860000);
    }
    final r = sampler.sample(px)!;
    expect(r.color.distanceTo(Oklab.fromHex('#800000')), lessThan(0.01));
    expect(r.warnings, isNot(contains(SampleWarning.mixedColors)));
  });

  test('reflexo minoritário é removido e avisado', () {
    final px = [...List.filled(90, 0x0000AA), ...List.filled(10, 0xFFFFFF)];
    final r = sampler.sample(px)!;
    expect(r.warnings, contains(SampleWarning.highlightRemoved));
    expect(r.color.toHex(), '#0000AA');
    expect(r.pixelCount, 90);
  });

  test('área toda branca continua branca', () {
    final r = sampler.sample(List.filled(50, 0xFFFFFF))!;
    expect(r.color.l, closeTo(1, 1e-3));
    expect(r.warnings, isNot(contains(SampleWarning.highlightRemoved)));
    expect(r.warnings, contains(SampleWarning.overexposed));
  });

  test('duas cores grandes e distantes: avisa e usa a maior', () {
    final px = [...List.filled(60, 0xFF0000), ...List.filled(40, 0x0000FF)];
    final r = sampler.sample(px)!;
    expect(r.warnings, contains(SampleWarning.mixedColors));
    expect(r.color.distanceTo(Oklab.fromHex('#FF0000')), lessThan(0.01));
  });

  test('grupo pequeno não dispara "misturado"', () {
    final px = [...List.filled(85, 0xFF0000), ...List.filled(15, 0x0000FF)];
    final r = sampler.sample(px)!;
    expect(r.warnings, isNot(contains(SampleWarning.mixedColors)));
  });

  test('pouca luz', () {
    final r = sampler.sample(List.filled(30, 0x040404))!;
    expect(r.warnings, contains(SampleWarning.lowLight));
  });

  test('superexposição', () {
    final px = [...List.filled(50, 0xFFFF80), ...List.filled(50, 0xF0F070)];
    final r = sampler.sample(px)!;
    expect(r.warnings, contains(SampleWarning.overexposed));
  });

  group('leitura de pixels', () {
    test('RGBA: só a área circular em volta do ponto', () {
      const w = 50, h = 50;
      final bytes = Uint8List(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final red = x >= 20 && x <= 30 && y >= 20 && y <= 30;
          final i = (y * w + x) * 4;
          bytes[i] = red ? 255 : 0;
          bytes[i + 2] = red ? 0 : 255;
          bytes[i + 3] = 255;
        }
      }
      final px = pixelsFromRgba(
        width: w,
        height: h,
        bytes: bytes,
        cx: 25,
        cy: 25,
        radius: 4,
      );
      expect(px, isNotEmpty);
      expect(px.every((p) => p == 0xFF0000), isTrue);
      // borda da imagem: não estoura
      expect(
        pixelsFromRgba(
          width: w,
          height: h,
          bytes: bytes,
          cx: 0,
          cy: 0,
          radius: 5,
        ),
        isNotEmpty,
      );
    });

    test('BGRA8888', () {
      const w = 8, h = 8;
      final bytes = Uint8List(w * h * 4);
      for (var i = 0; i < w * h; i++) {
        bytes[i * 4] = 0x30; // B
        bytes[i * 4 + 1] = 0x20; // G
        bytes[i * 4 + 2] = 0x10; // R
        bytes[i * 4 + 3] = 0xFF;
      }
      final px = pixelsFromBgra8888(
        width: w,
        height: h,
        bytes: bytes,
        bytesPerRow: w * 4,
        cx: 4,
        cy: 4,
        radius: 2,
      );
      expect(px.toSet(), {0x102030});
    });

    test('YUV420: cinza médio e vermelho', () {
      const w = 8, h = 8;
      Uint8List plane(int n, int v) => Uint8List(n)..fillRange(0, n, v);
      var px = pixelsFromYuv420(
        width: w,
        height: h,
        yPlane: plane(w * h, 128),
        yRowStride: w,
        uPlane: plane(w * h ~/ 4, 128),
        vPlane: plane(w * h ~/ 4, 128),
        uvRowStride: w ~/ 2,
        uvPixelStride: 1,
        cx: 4,
        cy: 4,
        radius: 2,
      );
      expect(px.toSet(), {0x808080});
      // Y=76, U=85, V=255 ≈ vermelho puro (BT.601)
      px = pixelsFromYuv420(
        width: w,
        height: h,
        yPlane: plane(w * h, 76),
        yRowStride: w,
        uPlane: plane(w * h ~/ 4, 85),
        vPlane: plane(w * h ~/ 4, 255),
        uvRowStride: w ~/ 2,
        uvPixelStride: 1,
        cx: 4,
        cy: 4,
        radius: 2,
      );
      final c = Oklab.fromRgbInt(px.first);
      expect(c.distanceTo(Oklab.fromHex('#FF0000')), lessThan(0.03));
    });
  });
}
