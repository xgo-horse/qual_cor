import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Vale para todos os testes: carrega as fontes embutidas de verdade
/// (Fraunces, Inter, JetBrains Mono). Sem isso o flutter_test usa uma
/// fonte de letras quadradas, bem mais larga, e as medições de "cabe numa
/// linha" ficariam irreais.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Fraunces', ['Fraunces.ttf', 'Fraunces-Italic.ttf']);
  await load('Inter', ['Inter.ttf']);
  await load('JetBrains Mono', ['JetBrainsMono.ttf']);
  await testMain();
}
