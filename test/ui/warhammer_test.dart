import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qual_cor/app.dart';
import 'package:qual_cor/color/citadel_namer.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/oklab.dart';
import 'package:qual_cor/l10n/generated/app_localizations_pt.dart';
import 'package:qual_cor/ui/about_page.dart';
import 'package:qual_cor/ui/describe_text.dart';
import 'package:qual_cor/ui/result_card.dart';
import 'package:qual_cor/ui/style.dart';
import 'package:qual_cor/warhammer_mode.dart';

void main() {
  final citadel = CitadelNamer.fromJson(
    File(CitadelNamer.asset).readAsStringSync(),
  );
  final namer = ColorNamer();
  final l10n = AppLocalizationsPt();
  ColorDescription d(String hex) => namer.describe(Oklab.fromHex(hex));

  tearDown(warhammer.resetForTest);

  group('frases no Modo Warhammer', () {
    test('preto: Abaddon Black, família em português', () {
      final t = DescriptionTexts(
        l10n,
        d('#000000'),
        const {},
        citadel: citadel,
      );
      expect(t.headline, 'Abaddon Black');
      expect(t.label, 'PIGMENTO · BASE');
      expect(t.cardDescription, 'Cor: preto');
      expect(t.footer, 'Citadel Base');
      expect(t.hex, '#000000');
      expect(
        t.accessibleText,
        'O cogitador identificou: Abaddon Black, linha Base. Cor: preto.',
      );
    });

    test('hex de Mephiston Red', () {
      final t = DescriptionTexts(
        l10n,
        d('#960C09'),
        const {},
        citadel: citadel,
      );
      expect(t.headline, 'Mephiston Red');
      expect(t.cardDescription, startsWith('Cor: vermelho'));
      expect(t.hexLabel, 'Pigmento #960C09');
    });

    test('longe de tudo: "lembra"', () {
      final t = DescriptionTexts(
        l10n,
        d('#00FF00'),
        const {},
        citadel: citadel,
      );
      expect(t.label, startsWith('LEMBRA · '));
      expect(t.accessibleText, contains('algo que lembra'));
    });

    test('sem o modo, nada muda', () {
      final t = DescriptionTexts(l10n, d('#000080'), const {});
      expect(t.paint, isNull);
      expect(t.headline, 'Azul');
      expect(t.footer, 'azul-marinho');
    });
  });

  group('ativação', () {
    Future<void> pumpAbout(WidgetTester tester) async {
      warhammer.resetForTest();
      await tester.pumpWidget(const QualCorApp(home: AboutPage()));
    }

    Future<void> tapVersion(WidgetTester tester, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.byKey(const Key('about-version')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      // O carregamento das tintas é assíncrono (rootBundle).
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    testWidgets('6 toques não fazem nada; 7 ligam e mostram o aviso', (
      tester,
    ) async {
      await pumpAbout(tester);
      expect(find.byKey(const Key('warhammer-switch')), findsNothing);
      await tapVersion(tester, 6);
      expect(warhammer.enabled, isFalse);
      await tapVersion(tester, 1);
      expect(warhammer.enabled, isTrue);
      expect(warhammer.discovered, isTrue);
      // Deixa a transição do tema e a entrada do aviso terminarem.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Modo Warhammer ativado'), findsOneWidget);
      expect(find.byKey(const Key('warhammer-switch')), findsOneWidget);
      expect(find.byKey(const Key('warhammer-disclaimer')), findsOneWidget);
      expect(find.textContaining('Games Workshop Ltd'), findsOneWidget);
      // O tema muda junto.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        Theme.of(tester.element(find.byWidget(scaffold))).brightness,
        Brightness.dark,
      );
      expect(Palette.ground, Grim.black);
    });

    testWidgets('pausa longa recomeça a contagem', (tester) async {
      await pumpAbout(tester);
      await tapVersion(tester, 4);
      await tester.pump(const Duration(seconds: 2));
      await tapVersion(tester, 3);
      expect(warhammer.enabled, isFalse);
    });

    testWidgets('mais 7 toques desligam; o switch continua', (tester) async {
      await pumpAbout(tester);
      await tapVersion(tester, 7);
      expect(warhammer.enabled, isTrue);
      await tester.pump(const Duration(seconds: 3));
      await tapVersion(tester, 7);
      expect(warhammer.enabled, isFalse);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Modo Warhammer desativado'), findsOneWidget);
      expect(find.byKey(const Key('warhammer-switch')), findsOneWidget);
      expect(find.byKey(const Key('warhammer-disclaimer')), findsNothing);
    });

    testWidgets('cartão mostra a tinta com o modo ligado', (tester) async {
      await tester.runAsync(() => warhammer.setEnabled(true));
      expect(warhammer.enabled, isTrue);
      await tester.pumpWidget(
        QualCorApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResultCard(description: d('#960C09')),
            ),
          ),
        ),
      );
      expect(find.text('Mephiston Red'), findsOneWidget);
      expect(find.text('Citadel Base'), findsOneWidget);
      expect(find.text('960C09'), findsOneWidget);
      expect(find.byKey(const Key('paint-swatch')), findsOneWidget);
    });
  });

  test('estado salvo volta na próxima abertura', () async {
    final dir = Directory.systemTemp.createTempSync('qual_cor_wh');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = ModeStore(File('${dir.path}/s.json'));
    final first = WarhammerMode(store: store, loadNamer: () async => citadel);
    await first.setEnabled(true);

    final second = WarhammerMode(store: store, loadNamer: () async => citadel);
    await second.restore();
    expect(second.enabled, isTrue);
    expect(second.discovered, isTrue);

    await second.setEnabled(false);
    final third = WarhammerMode(store: store, loadNamer: () async => citadel);
    await third.restore();
    expect(third.enabled, isFalse);
    expect(third.discovered, isTrue);
  });

  test('arquivo corrompido não quebra', () async {
    final dir = Directory.systemTemp.createTempSync('qual_cor_wh');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/s.json')..writeAsStringSync('{{{');
    final mode = WarhammerMode(
      store: ModeStore(file),
      loadNamer: () async => citadel,
    );
    await mode.restore();
    expect(mode.enabled, isFalse);
  });
}
