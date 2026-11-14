import 'package:material_ui/material_ui.dart';

import 'l10n/generated/app_localizations.dart';
import 'ui/live_page.dart';
import 'ui/style.dart';
import 'warhammer_mode.dart';

/// Dá acesso ao [WarhammerMode] pela árvore e reconstrói quem chama
/// [WarhammerScope.of] quando o modo muda.
class WarhammerScope extends InheritedNotifier<WarhammerMode> {
  const WarhammerScope({
    super.key,
    required WarhammerMode super.notifier,
    required super.child,
  });

  static WarhammerMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WarhammerScope>()?.notifier ??
      warhammer;
}

class QualCorApp extends StatefulWidget {
  const QualCorApp({super.key, this.home = const LivePage()});

  final Widget home;

  @override
  State<QualCorApp> createState() => _QualCorAppState();
}

class _QualCorAppState extends State<QualCorApp> {
  bool _grim = warhammer.enabled;

  @override
  void initState() {
    super.initState();
    warhammer.addListener(_onMode);
  }

  @override
  void dispose() {
    warhammer.removeListener(_onMode);
    super.dispose();
  }

  /// A paleta e as fontes são lidas direto de [warhammer] (lib/ui/style.dart),
  /// então ao trocar de modo todo widget precisa ser refeito, inclusive os
  /// das telas empilhadas (a Sobre fica por cima da mira). O estado das
  /// telas (câmera, foto) é mantido.
  void _onMode() {
    if (_grim == warhammer.enabled) return;
    setState(() => _grim = warhammer.enabled);
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return WarhammerScope(
      notifier: warhammer,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: widget.home,
      ),
    );
  }
}
