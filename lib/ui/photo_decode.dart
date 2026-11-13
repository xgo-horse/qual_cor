import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Foto decodificada: a imagem para mostrar e os mesmos pixels em RGBA para
/// amostrar (assim o toque sempre cai no pixel certo).
class DecodedPhoto {
  DecodedPhoto(this.image, this.rgba);

  final ui.Image image;
  final Uint8List rgba;

  int get width => image.width;
  int get height => image.height;

  void dispose() => image.dispose();
}

/// Lado maior máximo em memória: sobra para achar a cor de uma área e deixa
/// a decodificação rápida.
const int photoMaxSide = 2048;

/// Decodifica com o decodificador nativo do Flutter (fora da thread da
/// interface), já reduzindo para [maxSide] no lado maior.
Future<DecodedPhoto> decodePhoto(
  Uint8List bytes, {
  int maxSide = photoMaxSide,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final w = descriptor.width, h = descriptor.height;
  final scale = math.min(1.0, maxSide / math.max(w, h));
  // Só um lado: o outro acompanha a proporção (e nada distorce se a foto
  // tiver rotação EXIF).
  final codec = await descriptor.instantiateCodec(
    targetWidth: w >= h ? (w * scale).round() : null,
    targetHeight: h > w ? (h * scale).round() : null,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return DecodedPhoto(frame.image, data!.buffer.asUint8List());
}
