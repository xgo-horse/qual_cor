/// Registra licenças extras (fontes, dados, ícones) na tela de licenças do
/// Flutter, aberta em Sobre > Licenças.
///
/// As licenças dos pacotes do pubspec entram sozinhas. Para outra fonte:
/// coloque o texto em `assets/licenses/` (e declare a pasta nos assets do
/// pubspec) e adicione aqui, por exemplo:
///
/// ```dart
/// LicenseRegistry.addLicense(() async* {
///   final text = await rootBundle.loadString('assets/licenses/OFL-Fraunces.txt');
///   yield LicenseEntryWithLineBreaks(['Fraunces'], text);
/// });
/// ```
void registerLicenses() {
  // Por enquanto nada além das licenças dos pacotes (ponto de extensão).
}
