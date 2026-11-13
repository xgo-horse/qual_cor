import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Funções que leem os pixels de uma área circular e devolvem inteiros
/// 0xRRGGBB. O passo entre pixels cresce com o raio para limitar a conta a
/// cerca de [maxSamples] pixels.

int _stepFor(int radius, int maxSamples) {
  final area = math.pi * radius * radius;
  return math.max(1, math.sqrt(area / maxSamples).ceil());
}

/// Pixels de uma imagem já decodificada (package:image).
List<int> pixelsFromImage(
  img.Image image,
  int cx,
  int cy,
  int radius, {
  int maxSamples = 2500,
}) {
  final out = <int>[];
  final r = math.max(0, radius);
  final step = _stepFor(math.max(1, r), maxSamples);
  final r2 = r * r;
  for (var dy = -r; dy <= r; dy += step) {
    final y = cy + dy;
    if (y < 0 || y >= image.height) continue;
    for (var dx = -r; dx <= r; dx += step) {
      if (dx * dx + dy * dy > r2) continue;
      final x = cx + dx;
      if (x < 0 || x >= image.width) continue;
      final p = image.getPixel(x, y);
      out.add(
        (p.rNormalized * 255).round() << 16 |
            (p.gNormalized * 255).round() << 8 |
            (p.bNormalized * 255).round(),
      );
    }
  }
  return out;
}

/// Pixels de um quadro YUV420 (Android). Conversão BT.601 de faixa cheia,
/// que é a usada pelas câmeras do Android.
List<int> pixelsFromYuv420({
  required int width,
  required int height,
  required Uint8List yPlane,
  required int yRowStride,
  required Uint8List uPlane,
  required Uint8List vPlane,
  required int uvRowStride,
  required int uvPixelStride,
  required int cx,
  required int cy,
  required int radius,
  int maxSamples = 600,
}) {
  final out = <int>[];
  final step = _stepFor(math.max(1, radius), maxSamples);
  final r2 = radius * radius;
  for (var dy = -radius; dy <= radius; dy += step) {
    final y = cy + dy;
    if (y < 0 || y >= height) continue;
    for (var dx = -radius; dx <= radius; dx += step) {
      if (dx * dx + dy * dy > r2) continue;
      final x = cx + dx;
      if (x < 0 || x >= width) continue;
      final yi = y * yRowStride + x;
      final uvi = (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;
      if (yi >= yPlane.length || uvi >= uPlane.length || uvi >= vPlane.length) {
        continue;
      }
      final yy = yPlane[yi].toDouble();
      final u = uPlane[uvi] - 128.0;
      final v = vPlane[uvi] - 128.0;
      final r = (yy + 1.402 * v).round().clamp(0, 255);
      final g = (yy - 0.344136 * u - 0.714136 * v).round().clamp(0, 255);
      final b = (yy + 1.772 * u).round().clamp(0, 255);
      out.add(r << 16 | g << 8 | b);
    }
  }
  return out;
}

/// Pixels de um quadro BGRA8888 (iOS).
List<int> pixelsFromBgra8888({
  required int width,
  required int height,
  required Uint8List bytes,
  required int bytesPerRow,
  required int cx,
  required int cy,
  required int radius,
  int maxSamples = 600,
}) {
  final out = <int>[];
  final step = _stepFor(math.max(1, radius), maxSamples);
  final r2 = radius * radius;
  for (var dy = -radius; dy <= radius; dy += step) {
    final y = cy + dy;
    if (y < 0 || y >= height) continue;
    for (var dx = -radius; dx <= radius; dx += step) {
      if (dx * dx + dy * dy > r2) continue;
      final x = cx + dx;
      if (x < 0 || x >= width) continue;
      final i = y * bytesPerRow + x * 4;
      if (i + 2 >= bytes.length) continue;
      out.add(bytes[i + 2] << 16 | bytes[i + 1] << 8 | bytes[i]);
    }
  }
  return out;
}
