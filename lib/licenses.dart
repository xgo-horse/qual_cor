import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tipo de licença própria do app: decide a seção em Sobre > Licenças.
enum AppLicenseKind {
  /// Seção "Fontes".
  font,

  /// Seção "Dados" (aparece só se houver alguma).
  data,
}

/// Uma licença que o app traz além das dos pacotes (fontes, conjuntos de
/// dados, ícones…).
class AppLicense {
  const AppLicense({
    required this.name,
    required this.kind,
    required this.asset,
    required this.licenseName,
  });

  /// Nome mostrado na lista (ex.: "Fraunces").
  final String name;
  final AppLicenseKind kind;

  /// Texto completo da licença, em assets/licenses/.
  final String asset;

  /// Nome curto da licença (ex.: "SIL Open Font License 1.1").
  final String licenseName;
}

/// Licenças próprias do app.
///
/// Para acrescentar uma (ex.: um conjunto de dados de cores): ponha o texto
/// em `assets/licenses/` (a pasta já está nos assets do pubspec) e adicione
/// uma entrada aqui com o `kind` certo. Ela aparece sozinha na seção
/// correspondente da tela de licenças (lib/ui/licenses_page.dart) e também
/// na lista completa do Flutter; não precisa mexer na interface.
const appLicenses = <AppLicense>[
  AppLicense(
    name: 'Fraunces',
    kind: AppLicenseKind.font,
    asset: 'assets/licenses/OFL-Fraunces.txt',
    licenseName: 'SIL Open Font License 1.1',
  ),
  AppLicense(
    name: 'Inter',
    kind: AppLicenseKind.font,
    asset: 'assets/licenses/OFL-Inter.txt',
    licenseName: 'SIL Open Font License 1.1',
  ),
  AppLicense(
    name: 'JetBrains Mono',
    kind: AppLicenseKind.font,
    asset: 'assets/licenses/OFL-JetBrainsMono.txt',
    licenseName: 'SIL Open Font License 1.1',
  ),
];

bool _registered = false;

/// Registra as [appLicenses] na tela de licenças do Flutter (as dos pacotes
/// do pubspec entram sozinhas). Chamado no main(); pode ser chamado de novo.
void registerLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final l in appLicenses) {
      final text = await rootBundle.loadString(l.asset);
      yield LicenseEntryWithLineBreaks([l.name], text);
    }
  });
}

/// Quantos pacotes de terceiros (Flutter e pacotes do pubspec) aparecem na
/// lista completa, sem contar as [appLicenses].
Future<int> countPackageLicenses() async {
  final own = {for (final l in appLicenses) l.name};
  final names = <String>{};
  await for (final entry in LicenseRegistry.licenses) {
    names.addAll(entry.packages.where((p) => !own.contains(p)));
  }
  return names.length;
}
