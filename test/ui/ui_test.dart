import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qual_cor/app.dart';
import 'package:qual_cor/color/area_sampler.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/oklab.dart';
import 'package:qual_cor/l10n/generated/app_localizations.dart';
import 'package:qual_cor/l10n/generated/app_localizations_pt.dart';
import 'package:qual_cor/ui/describe_text.dart';
import 'package:qual_cor/ui/result_card.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('pt'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  final namer = ColorNamer();
  final l10n = AppLocalizationsPt();
  ColorDescription d(String hex) => namer.describe(Oklab.fromHex(hex));

  group('frases (ARB)', () {
    test('azul-marinho', () {
      final t = DescriptionTexts(l10n, d('#000080'), const {});
      expect(t.main, 'Azul');
      expect(t.details, 'escuro');
      expect(t.popularName, 'Parecido com: azul-marinho');
      expect(t.accessibleText, 'Azul escuro. Parecido com: azul-marinho.');
    });

    test('entre duas famílias', () {
      final t = DescriptionTexts(l10n, d('#EE82EE'), const {});
      expect(t.main, anyOf('Entre roxo e rosa', 'Entre rosa e roxo'));
    });

    test('subtom e avisos', () {
      final t = DescriptionTexts(l10n, d('#708090'), {SampleWarning.lowLight});
      expect(t.main, 'Cinza');
      expect(t.details, 'puxando para o azul');
      expect(t.warningTexts, [l10n.warningLowLight]);
      expect(t.accessibleText, contains(l10n.warningLowLight));
    });
  });

  testWidgets('início mostra os três botões grandes', (tester) async {
    await tester.pumpWidget(const QualCorApp());
    await tester.pumpAndSettle();
    expect(find.text('Qual cor?'), findsOneWidget);
    expect(find.text('Mira ao vivo'), findsOneWidget);
    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsOneWidget);
  });

  testWidgets('cartão de resultado: textos, código e acessibilidade', (
    tester,
  ) async {
    Widget card({required bool showHex}) => wrap(
      ResultCard(
        description: d('#000080'),
        warnings: const {SampleWarning.mixedColors},
        showHex: showHex,
      ),
    );
    await tester.pumpWidget(card(showHex: false));
    expect(find.text('Azul'), findsOneWidget);
    expect(find.text('escuro'), findsOneWidget);
    expect(find.text('Parecido com: azul-marinho'), findsOneWidget);
    expect(find.text(l10n.warningMixed), findsOneWidget);
    expect(find.text('Código: #000080'), findsNothing);
    expect(find.text('Falar'), findsNothing);

    await tester.pumpWidget(card(showHex: true));
    expect(find.text('Código: #000080'), findsOneWidget);

    // região "ao vivo" com o resultado completo para o leitor de tela
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp(r'^Azul escuro\. Parecido com')),
      findsOneWidget,
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Azul escuro\.')),
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });
}
