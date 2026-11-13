import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/ui/photo_decode.dart';

/// Tempo de decodificação de uma foto de 12 MP (4032x3024) com o
/// decodificador nativo, reduzindo para 2048 no lado maior. Usa a foto em
/// FOTO_12MP (caminho de um JPEG); sem ela, o teste é pulado.
/// Referência: com o package:image (versão anterior) eram ~540 ms no Mac,
/// tudo num isolate.
void main() {
  final path = Platform.environment['FOTO_12MP'];
  testWidgets('decodificação de foto 12 MP', (tester) async {
    final bytes = File(path!).readAsBytesSync();
    final times = <int>[];
    for (var i = 0; i < 3; i++) {
      final sw = Stopwatch()..start();
      final p = (await tester.runAsync(() => decodePhoto(bytes)))!;
      sw.stop();
      times.add(sw.elapsedMilliseconds);
      expect(p.width, 2048);
      p.dispose();
    }
    // ignore: avoid_print
    print('foto 12 MP nativa: $times ms (inclui a cópia RGBA)');
  }, skip: path == null);
}
