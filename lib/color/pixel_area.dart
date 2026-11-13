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

/// Recorte de um quadro de câmera em volta do centro, com só as linhas e
/// colunas necessárias. É o que vai para o isolate de amostragem (bem menos
/// bytes que o quadro inteiro).
class FrameCrop {
  const FrameCrop.yuv420({
    required this.width,
    required this.height,
    required Uint8List this.y,
    required Uint8List this.u,
    required Uint8List this.v,
    required this.uvPixelStride,
    required this.cx,
    required this.cy,
    required this.radius,
  }) : bgra = null;

  const FrameCrop.bgra8888({
    required this.width,
    required this.height,
    required Uint8List this.bgra,
    required this.cx,
    required this.cy,
    required this.radius,
  }) : y = null,
       u = null,
       v = null,
       uvPixelStride = 0;

  final int width, height;
  final Uint8List? y, u, v, bgra;
  final int uvPixelStride;
  final int cx, cy, radius;

  /// Pixels 0xRRGGBB da área circular.
  List<int> pixels() {
    if (bgra != null) {
      return pixelsFromBgra8888(
        width: width,
        height: height,
        bytes: bgra!,
        bytesPerRow: width * 4,
        cx: cx,
        cy: cy,
        radius: radius,
      );
    }
    return pixelsFromYuv420(
      width: width,
      height: height,
      yPlane: y!,
      yRowStride: width,
      uPlane: u!,
      vPlane: v!,
      uvRowStride: (width ~/ 2) * uvPixelStride,
      uvPixelStride: uvPixelStride,
      cx: cx,
      cy: cy,
      radius: radius,
    );
  }
}

/// Retângulo do recorte, com origem par (para o croma 2x2 do YUV420).
(int, int, int, int) _cropRect(int w, int h, int cx, int cy, int radius) {
  final x0 = math.max(0, cx - radius) & ~1;
  final y0 = math.max(0, cy - radius) & ~1;
  final x1 = math.min(w, cx + radius + 2);
  final y1 = math.min(h, cy + radius + 2);
  return (x0, y0, (x1 - x0) & ~1, (y1 - y0) & ~1);
}

FrameCrop cropYuv420({
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
}) {
  final (x0, y0, cw, ch) = _cropRect(width, height, cx, cy, radius);
  final y = Uint8List(cw * ch);
  for (var r = 0; r < ch; r++) {
    final src = (y0 + r) * yRowStride + x0;
    y.setRange(r * cw, r * cw + cw, yPlane, src);
  }
  final uvRow = (cw ~/ 2) * uvPixelStride;
  final uvRows = ch ~/ 2;
  final u = Uint8List(uvRow * uvRows), v = Uint8List(uvRow * uvRows);
  for (var r = 0; r < uvRows; r++) {
    final src = ((y0 >> 1) + r) * uvRowStride + (x0 >> 1) * uvPixelStride;
    final n = math.min(uvRow, math.min(uPlane.length, vPlane.length) - src);
    if (n <= 0) break;
    u.setRange(r * uvRow, r * uvRow + n, uPlane, src);
    v.setRange(r * uvRow, r * uvRow + n, vPlane, src);
  }
  return FrameCrop.yuv420(
    width: cw,
    height: ch,
    y: y,
    u: u,
    v: v,
    uvPixelStride: uvPixelStride,
    cx: cx - x0,
    cy: cy - y0,
    radius: radius,
  );
}

FrameCrop cropBgra8888({
  required int width,
  required int height,
  required Uint8List bytes,
  required int bytesPerRow,
  required int cx,
  required int cy,
  required int radius,
}) {
  final (x0, y0, cw, ch) = _cropRect(width, height, cx, cy, radius);
  final out = Uint8List(cw * ch * 4);
  for (var r = 0; r < ch; r++) {
    final src = (y0 + r) * bytesPerRow + x0 * 4;
    out.setRange(r * cw * 4, (r + 1) * cw * 4, bytes, src);
  }
  return FrameCrop.bgra8888(
    width: cw,
    height: ch,
    bgra: out,
    cx: cx - x0,
    cy: cy - y0,
    radius: radius,
  );
}
