import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/ui/photo_decode.dart';

int rgbAt(DecodedPhoto p, int x, int y) {
  final i = (y * p.width + x) * 4;
  return p.rgba[i] << 16 | p.rgba[i + 1] << 8 | p.rgba[i + 2];
}

bool reddish(int c) => (c >> 16) > 180 && (c & 0xFF) < 80;
bool bluish(int c) => (c & 0xFF) > 180 && (c >> 16) < 80;

void main() {
  testWidgets('JPEG com orientação EXIF 6 sai em pé', (tester) async {
    // Gravado 40x20 (esquerda vermelha, direita azul) com orientação 6:
    // mostrado em pé fica 20x40, vermelho em cima e azul embaixo.
    final bytes = File('test/fixtures/orientacao6.jpg').readAsBytesSync();
    final p = (await tester.runAsync(() => decodePhoto(bytes)))!;
    // ignore: avoid_print
    print(
      'decodificado ${p.width}x${p.height}, topo=${rgbAt(p, 10, 3).toRadixString(16)}, fundo=${rgbAt(p, 10, 36).toRadixString(16)}',
    );
    expect((p.width, p.height), (20, 40));
    expect(reddish(rgbAt(p, 10, 3)), isTrue);
    expect(bluish(rgbAt(p, 10, 36)), isTrue);
    p.dispose();
  });
}
