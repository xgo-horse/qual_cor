import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../licenses.dart';
import 'about_page.dart' show appVersion;
import 'style.dart';

/// Licenças no estilo cartela: primeiro o próprio app e o que ele traz
/// (fontes, dados — vindos de [appLicenses]); por último um item que abre a
/// lista completa do Flutter com todos os componentes de código aberto.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  late final Future<int> _count = countPackageLicenses();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fonts = appLicenses.where((l) => l.kind == AppLicenseKind.font);
    final data = appLicenses.where((l) => l.kind == AppLicenseKind.data);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.licensesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionLabel(l10n.licensesThisApp),
            _Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.appTitle, style: Txt.serif(size: 28)),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.aboutVersion(appVersion)} · ${l10n.appCopyright}',
                      style: Txt.sans(size: 13, color: Palette.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.licensesAppLine, style: Txt.description()),
                  ],
                ),
              ),
            ),
            if (fonts.isNotEmpty) ...[
              _SectionLabel(l10n.licensesFonts),
              _LicenseList(items: fonts.toList()),
            ],
            if (data.isNotEmpty) ...[
              _SectionLabel(l10n.licensesData),
              _LicenseList(items: data.toList()),
            ],
            _SectionLabel(l10n.licensesOpenSource),
            _Card(
              child: FutureBuilder<int>(
                future: _count,
                builder: (context, snap) => _Row(
                  key: const Key('licenses-components'),
                  title: l10n.licensesComponents,
                  subtitle: snap.hasData
                      ? l10n.licensesComponentsCount(snap.data!)
                      : l10n.licensesCounting,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appTitle,
                    applicationVersion: appVersion,
                    applicationLegalese: l10n.appCopyright,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 20, 0, 8),
    child: Semantics(header: true, child: Text(text, style: Txt.label())),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Palette.surface,
      boxShadow: Palette.cardShadow,
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class _LicenseList extends StatelessWidget {
  const _LicenseList({required this.items});

  final List<AppLicense> items;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, indent: 18, color: Palette.hairlineLight),
          _Row(
            key: Key('license-${items[i].name}'),
            title: items[i].name,
            subtitle: items[i].licenseName,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LicenseTextPage(license: items[i]),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Txt.sans(size: 16, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Txt.sans(size: 13, color: Palette.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Palette.muted),
          ],
        ),
      ),
    ),
  );
}

/// Texto completo de uma licença própria (ex.: OFL de uma fonte).
class LicenseTextPage extends StatelessWidget {
  const LicenseTextPage({super.key, required this.license});

  final AppLicense license;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(license.name)),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString(license.asset),
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 4, 0, 8),
                child: Text(
                  license.licenseName.toUpperCase(),
                  style: Txt.label(),
                ),
              ),
              _Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    snap.data ?? '',
                    key: const Key('license-text'),
                    style: Txt.sans(
                      size: 13,
                      color: Palette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
