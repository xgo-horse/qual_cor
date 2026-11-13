import 'package:material_ui/material_ui.dart';

import 'l10n/generated/app_localizations.dart';
import 'ui/home_page.dart';

/// Tema escuro de alto contraste: fundo preto, texto branco e destaque
/// amarelo (cores que a maioria dos daltônicos distingue bem). Tamanhos
/// padrão do Material 3; quem precisa de letra maior usa o tamanho de texto
/// do sistema, que o app respeita.
ThemeData buildTheme() {
  const accent = Color(0xFFFFD600);
  final scheme = const ColorScheme.dark(
    primary: accent,
    onPrimary: Colors.black,
    secondary: Colors.white,
    onSecondary: Colors.black,
    surface: Colors.black,
    onSurface: Colors.white,
    surfaceContainerHighest: Color(0xFF1E1E1E),
    outline: Colors.white,
    error: Color(0xFFFF8A80),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF151515),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white54, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accent,
      inactiveTrackColor: Colors.white38,
    ),
  );
}

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
      home: const HomePage(),
    );
  }
}
