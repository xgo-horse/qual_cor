import 'dart:async';

import 'package:qual_cor/ui/style.dart';

/// Vale para todos os testes: sem rede, usa a fonte padrão em vez de baixar
/// as do google_fonts.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Txt.useGoogleFonts = false;
  await testMain();
}
