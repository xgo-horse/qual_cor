import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import 'style.dart';

/// Versão mostrada em Sobre. Mantenha igual ao `version` do pubspec.yaml
/// (sem o número de build); um teste confere.
const appVersion = '0.1.0';

/// Tela "Sobre o app", no estilo cartela: nome, versão, descrição e o item
/// "Licenças" (abre a tela de licenças do Flutter; licenças extras são
/// registradas em `lib/licenses.dart`).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Palette.surface,
                boxShadow: Palette.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutVersion(appVersion).toUpperCase(),
                      style: Txt.label(),
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
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: appVersion,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
