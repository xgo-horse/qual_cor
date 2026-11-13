import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Fontes embutidas e o arquivo de licença de cada uma (em assets/licenses).
const _fontLicenses = {
  'Fraunces': 'assets/licenses/OFL-Fraunces.txt',
  'Inter': 'assets/licenses/OFL-Inter.txt',
  'JetBrains Mono': 'assets/licenses/OFL-JetBrainsMono.txt',
};

/// Registra licenças extras na tela de licenças do Flutter (Sobre >
/// Licenças). As dos pacotes do pubspec entram sozinhas.
///
/// Para outra fonte de dados ou recurso: ponha o texto em
/// `assets/licenses/` (a pasta já está nos assets do pubspec) e adicione
/// um `LicenseRegistry.addLicense` como o abaixo.
void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in _fontLicenses.entries) {
      final text = await rootBundle.loadString(path);
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
