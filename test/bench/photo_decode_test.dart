import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qual_cor/ui/photo_page.dart';

/// Quanto custa decodificar uma foto de 12 MP (4032x3024, JPEG) com
/// package:image + orientação + redução para 1600 px. É esse tempo que
/// travaria a tela se a decodificação não fosse num isolate (compute).
void main() {
  test('decodificação de foto 12 MP', () {
    final src = img.Image(width: 4032, height: 3024);
    for (final p in src) {
      p
        ..r = (p.x * 255 ~/ 4032)
        ..g = (p.y * 255 ~/ 3024)
        ..b = ((p.x * 7 + p.y * 13) % 256);
    }
    final jpeg = img.encodeJpg(src, quality: 90);
    final sw = Stopwatch()..start();
    const runs = 3;
    for (var i = 0; i < runs; i++) {
      expect(decodeForSampling(jpeg), isNotNull);
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'foto 12 MP (${(jpeg.length / 1e6).toStringAsFixed(1)} MB JPEG): '
      '${sw.elapsedMilliseconds ~/ runs} ms por foto',
    );
  });
}
