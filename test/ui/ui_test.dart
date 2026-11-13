import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qual_cor/app.dart';
import 'package:qual_cor/licenses.dart';
import 'package:qual_cor/ui/about_page.dart';
import 'package:qual_cor/ui/style.dart';
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

  testWidgets('o app abre direto na mira ao vivo', (tester) async {
    await tester.pumpWidget(const QualCorApp());
    await tester.pump();
    expect(find.byKey(const Key('gallery')), findsOneWidget);
    expect(find.byKey(const Key('freeze')), findsOneWidget);
    expect(find.byKey(const Key('torch')), findsOneWidget);
    expect(find.byKey(const Key('about')), findsOneWidget);
    expect(find.text('Aponte para um objeto'), findsOneWidget);
  });

  testWidgets('cartão de resultado: textos, hex e acessibilidade', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ResultCard(
          description: d('#000080'),
          warnings: const {SampleWarning.mixedColors},
        ),
      ),
    );
    expect(find.text('FAMÍLIA'), findsOneWidget);
    expect(find.text('Azul'), findsOneWidget);
    expect(find.text('escuro'), findsOneWidget);
    expect(find.text('azul-marinho'), findsOneWidget);
    // O hex aparece sempre, sem o '#'.
    expect(find.text('000080'), findsOneWidget);
    expect(find.text('Código'), findsNothing);
    expect(find.text('Falar'), findsNothing);

    // região "ao vivo" com o resultado completo para o leitor de tela
    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Azul escuro\. Parecido com')),
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    expect(find.bySemanticsLabel('Copiar código da cor'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('copiar põe "#RRGGBB" na área de transferência', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(wrap(ResultCard(description: d('#1F5F5B'))));
    final hex = d('#1F5F5B').color.toHex();
    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('copy-hex')));
    await tester.pump();
    expect(copied, [hex]);
    expect(hex, matches(RegExp(r'^#[0-9A-F]{6}$')));
    // ícone vira "ok" e aparece o aviso; depois de 1,5 s volta.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Código $hex copiado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
  });

  testWidgets('Sobre mostra versão e o item Licenças', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: const AboutPage(),
      ),
    );
    expect(find.text('Qual cor?'), findsOneWidget);
    expect(find.text('VERSÃO $appVersion'), findsOneWidget);
    expect(find.byKey(const Key('about-licenses')), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  test('versão de Sobre = versão do pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, v);
  });

  test('licenças das fontes embutidas aparecem em Licenças', () async {
    registerLicenses();
    final names = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      names.addAll(entry.packages);
    }
    expect(names, containsAll(['Fraunces', 'Inter', 'JetBrains Mono']));
  });
}
