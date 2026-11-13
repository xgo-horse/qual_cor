import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/area_sampler.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/live_smoother.dart';
import 'package:qual_cor/color/pixel_area.dart';

/// Custo por quadro da mira ao vivo (leitura dos pixels + conversão +
/// amostragem + suavização/nome) num quadro YUV420 720x480
/// (ResolutionPreset.medium). Tudo roda na thread da interface.
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
    final smoother = LiveSmoother(ColorNamer());
    const runs = 500;
    for (final fraction in [0.01, 0.04, 0.10]) {
      final radius = (h * fraction).round();
      final sw = Stopwatch()..start();
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
        smoother.add(sampler.sample(px)!.color);
      }
      sw.stop();
      final ms = sw.elapsedMicroseconds / runs / 1000;
      // ignore: avoid_print
      print(
        'área ${(fraction * 100).round()}% (raio $radius px): '
        '${ms.toStringAsFixed(3)} ms/quadro',
      );
      // Folga grande: entre dois quadros da câmera há ~33 ms.
      expect(ms, lessThan(5));
    }
  });
}
