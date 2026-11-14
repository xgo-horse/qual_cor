import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../l10n/generated/app_localizations.dart';
import 'licenses_page.dart';
import 'style.dart';

/// Versão mostrada em Sobre. Mantenha igual ao `version` do pubspec.yaml
/// (sem o número de build); um teste confere.
const appVersion = '0.1.0';

/// Tela "Sobre o app", no estilo cartela: nome, versão, descrição e o item
/// "Licenças" (abre [LicensesPage]; licenças próprias do app ficam em
/// `lib/licenses.dart`).
///
/// Easter egg: 7 toques seguidos na versão ligam ou desligam o Modo
/// Warhammer. Depois de descoberto, aparece um switch para ele.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  /// Toques seguidos na versão para trocar o modo.
  static const tapsToToggle = 7;

  /// Pausa máxima entre dois toques da sequência.
  static const tapGap = Duration(milliseconds: 1200);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _taps = 0;

  /// Zera a contagem se o próximo toque demorar.
  Timer? _gap;

  @override
  void dispose() {
    _gap?.cancel();
    super.dispose();
  }

  Future<void> _onVersionTap() async {
    _gap?.cancel();
    _gap = Timer(AboutPage.tapGap, () => _taps = 0);
    if (++_taps < AboutPage.tapsToToggle) return;
    _taps = 0;
    _gap?.cancel();
    final mode = WarhammerScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    await mode.toggle();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mode.enabled ? l10n.whModeOn : l10n.whModeOff),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = WarhammerScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.surface,
                boxShadow: Palette.cardShadow,
                border: Palette.cardBorder,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sem retorno visual nem semântico de botão: é segredo.
                    GestureDetector(
                      key: const Key('about-version'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _onVersionTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          l10n.aboutVersion(appVersion).toUpperCase(),
                          style: Txt.label(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.appTitle, style: Txt.family()),
                    const SizedBox(height: 8),
                    Text(l10n.aboutDescription, style: Txt.description()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Palette.surface,
              child: ListTile(
                key: const Key('about-licenses'),
                minTileHeight: 56,
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  l10n.aboutLicenses,
                  style: Txt.sans(size: 16, weight: FontWeight.w500),
                ),
                subtitle: Text(
                  l10n.aboutLicensesSubtitle,
                  style: Txt.sans(size: 13, color: Palette.muted),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LicensesPage()),
                ),
              ),
            ),
            if (mode.discovered) ...[
              const SizedBox(height: 16),
              Material(
                color: Palette.surface,
                child: SwitchListTile(
                  key: const Key('warhammer-switch'),
                  value: mode.enabled,
                  onChanged: (v) => mode.setEnabled(v),
                  title: Text(
                    l10n.whSwitch,
                    style: Txt.sans(size: 16, weight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    l10n.whSwitchSubtitle,
                    style: Txt.sans(size: 13, color: Palette.muted),
                  ),
                ),
              ),
            ],
            if (mode.enabled) ...[
              const SizedBox(height: 16),
              Text(
                l10n.whDisclaimer,
                key: const Key('warhammer-disclaimer'),
                style: Txt.sans(size: 12, color: Palette.muted, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
