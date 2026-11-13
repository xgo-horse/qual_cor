import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/camera/sampling_worker.dart';
import 'package:qual_cor/color/area_sampler.dart';
import 'package:qual_cor/color/pixel_area.dart';

(Uint8List, Uint8List, Uint8List) yuvFrame(int w, int h) {
  final y = Uint8List(w * h),
      u = Uint8List(w * h ~/ 4),
      v = Uint8List(w * h ~/ 4);
  for (var i = 0; i < y.length; i++) {
    y[i] = (i * 7919) % 256;
  }
  for (var i = 0; i < u.length; i++) {
    u[i] = (i * 31) % 256;
    v[i] = (i * 17 + 50) % 256;
  }
  return (y, u, v);
}

void main() {
  test(
    'recorte YUV420 dá exatamente os mesmos pixels que o quadro inteiro',
    () {
      const w = 64, h = 48;
      final (y, u, v) = yuvFrame(w, h);
      for (final (cx, cy, r) in [
        (32, 24, 6),
        (3, 3, 5),
        (60, 45, 8),
        (33, 25, 7),
      ]) {
        final full = pixelsFromYuv420(
          width: w,
          height: h,
          yPlane: y,
          yRowStride: w,
          uPlane: u,
          vPlane: v,
          uvRowStride: w ~/ 2,
          uvPixelStride: 1,
          cx: cx,
          cy: cy,
          radius: r,
        );
        final crop = cropYuv420(
          width: w,
          height: h,
          yPlane: y,
          yRowStride: w,
          uPlane: u,
          vPlane: v,
          uvRowStride: w ~/ 2,
          uvPixelStride: 1,
          cx: cx,
          cy: cy,
          radius: r,
        );
        expect(crop.pixels(), full, reason: '($cx,$cy,$r)');
        expect(crop.y!.length, lessThan(y.length));
      }
    },
  );

  test('recorte YUV420 com croma intercalado (pixelStride 2, Android)', () {
    const w = 32, h = 32;
    final y = Uint8List(w * h)..fillRange(0, w * h, 120);
    // U e V intercalados no mesmo buffer, como no Android.
    final uv = Uint8List(w * h ~/ 2);
    for (var i = 0; i < uv.length; i += 2) {
      uv[i] = 90;
      uv[i + 1] = 200;
    }
    final u = uv, v = Uint8List.sublistView(uv, 1);
    final full = pixelsFromYuv420(
      width: w,
      height: h,
      yPlane: y,
      yRowStride: w,
      uPlane: u,
      vPlane: v,
      uvRowStride: w,
      uvPixelStride: 2,
      cx: 16,
      cy: 16,
      radius: 5,
    );
    final crop = cropYuv420(
      width: w,
      height: h,
      yPlane: y,
      yRowStride: w,
      uPlane: u,
      vPlane: v,
      uvRowStride: w,
      uvPixelStride: 2,
      cx: 16,
      cy: 16,
      radius: 5,
    );
    expect(crop.pixels(), full);
  });

  test('recorte BGRA8888 dá os mesmos pixels', () {
    const w = 40, h = 30, bpr = w * 4 + 16; // linha com sobra, como no iOS
    final bytes = Uint8List(bpr * h);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = (i * 13) % 256;
    }
    final full = pixelsFromBgra8888(
      width: w,
      height: h,
      bytes: bytes,
      bytesPerRow: bpr,
      cx: 20,
      cy: 15,
      radius: 6,
    );
    final crop = cropBgra8888(
      width: w,
      height: h,
      bytes: bytes,
      bytesPerRow: bpr,
      cx: 20,
      cy: 15,
      radius: 6,
    );
    expect(crop.pixels(), full);
  });

  test('isolate de amostragem devolve o mesmo resultado e mede a ida e volta', () async {
    const w = 720, h = 480;
    final (y, u, v) = yuvFrame(w, h);
    final worker = await SamplingWorker.spawn();
    addTearDown(worker.dispose);
    final crop = cropYuv420(
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
      radius: 19,
    );
    final expected = const AreaSampler().sample(crop.pixels())!;
    final sw = Stopwatch()..start();
    const runs = 200;
    SampleResult? r;
    for (var i = 0; i < runs; i++) {
      r = await worker.sample(crop);
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'isolate: ida e volta ${(sw.elapsedMicroseconds / runs / 1000).toStringAsFixed(3)} ms',
    );
    expect(r!.color.toHex(), expected.color.toHex());
    expect(r.warnings, expected.warnings);
    // Um pedido por vez: o segundo simultâneo é recusado (quadro descartado).
    final f1 = worker.sample(crop);
    expect(worker.isBusy, isTrue);
    expect(await worker.sample(crop), isNull);
    expect(await f1, isNotNull);
  });
}
