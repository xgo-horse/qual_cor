import 'package:material_ui/material_ui.dart';

import 'l10n/generated/app_localizations.dart';
import 'ui/live_page.dart';
import 'ui/style.dart';

class QualCorApp extends StatelessWidget {
  const QualCorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const LivePage(),
    );
  }
}
