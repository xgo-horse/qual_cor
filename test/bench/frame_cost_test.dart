import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/area_sampler.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/live_smoother.dart';
import 'package:qual_cor/color/pixel_area.dart';

/// Custo por quadro da mira ao vivo na thread da interface, num quadro
/// YUV420 720x480 (ResolutionPreset.medium).
///   antes: leitura + conversão + amostragem + nome, tudo na thread da UI;
///   depois: só o recorte (cópia de alguns KB) + suavização/nome; a
///   conversão e a amostragem vão para o isolate.
void main() {
  test('custo por quadro na thread da interface', () {
    const w = 720, h = 480;
    final y = Uint8List(w * h);
    final u = Uint8List(w * h ~/ 4), v = Uint8List(w * h ~/ 4);
    for (var i = 0; i < y.length; i++) {
      y[i] = 80 + (i * 7919) % 40;
    }
    for (var i = 0; i < u.length; i++) {
      u[i] = 100 + (i * 31) % 20;
      v[i] = 170 + (i * 17) % 20;
    }
    const sampler = AreaSampler();
    final namer = ColorNamer();
    const runs = 500;
    for (final fraction in [0.01, 0.04, 0.10]) {
      final radius = (h * fraction).round();
      final before = Stopwatch()..start();
      for (var i = 0; i < runs; i++) {
        final px = pixelsFromYuv420(
          width: w,
          height: h,
          yPlane: y,
          yRowStride: w,
          uPlane: u,
          vPlane: v,
          uvRowStride: w ~/ 2,
          uvPixelStride: 1,
          cx: w ~/ 2,
          cy: h ~/ 2,
          radius: radius,
        );
        namer.describe(sampler.sample(px)!.color);
      }
      before.stop();
      final color = sampler
          .sample(
            pixelsFromYuv420(
              width: w,
              height: h,
              yPlane: y,
              yRowStride: w,
              uPlane: u,
              vPlane: v,
              uvRowStride: w ~/ 2,
              uvPixelStride: 1,
              cx: w ~/ 2,
              cy: h ~/ 2,
              radius: radius,
            ),
          )!
          .color;
      final smoother = LiveSmoother(namer);
      final after = Stopwatch()..start();
      for (var i = 0; i < runs; i++) {
        cropYuv420(
          width: w,
          height: h,
          yPlane: y,
          yRowStride: w,
          uPlane: u,
          vPlane: v,
          uvRowStride: w ~/ 2,
          uvPixelStride: 1,
          cx: w ~/ 2,
          cy: h ~/ 2,
          radius: radius,
        );
        smoother.add(color);
      }
      after.stop();
      String ms(Stopwatch s) =>
          (s.elapsedMicroseconds / runs / 1000).toStringAsFixed(3);
      // ignore: avoid_print
      print(
        'área ${(fraction * 100).round()}% (raio $radius px): antes ${ms(before)} ms, depois ${ms(after)} ms na thread da UI',
      );
      expect(before.elapsedMilliseconds / runs, lessThan(20));
    }
  });
}
