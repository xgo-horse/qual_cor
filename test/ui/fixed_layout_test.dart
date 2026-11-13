import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qual_cor/color/area_sampler.dart';
import 'package:qual_cor/color/color_names_pt.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/oklab.dart';
import 'package:qual_cor/l10n/generated/app_localizations.dart';
import 'package:qual_cor/ui/result_panel.dart';
import 'package:qual_cor/ui/style.dart';

/// Resultado curto: "Preto", sem descrição, sem avisos.
final short = ColorNamer().describe(Oklab.fromHex('#000000'));

/// Pior caso real de cada linha (os textos mais longos encontrados varrendo
/// 6007 cores): "Entre vermelho e laranja", "muito claro acinzentado,
/// puxando para o verde" e "Parecido com: vermelho-alaranjado", mais os 4
/// avisos de uma vez.
final long = ColorDescription(
  color: Oklab.fromHex('#B44B3C'),
  family: ColorFamily.vermelho,
  secondFamily: ColorFamily.laranja,
  lightness: Lightness.muitoClaro,
  saturation: Saturation.acinzentado,
  undertone: ColorFamily.verde,
  popularName: 'vermelho-alaranjado',
  closeness: NameCloseness.parecido,
  familyScores: const {},
);
const allWarnings = {...SampleWarning.values};

/// Imita a tela da mira: metade de cima "câmera", metade de baixo o painel.
class _Harness extends StatelessWidget {
  const _Harness(this.result);

  final ValueNotifier<(ColorDescription, Set<SampleWarning>)> result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(child: ColoredBox(color: Colors.grey)),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: result,
                  builder: (context, r, _) => ResultPanel(
                    description: r.$1,
                    warnings: r.$2,
                    areaFraction: 0.04,
                    onAreaChanged: (_) {},
                    bar: BottomBar(
                      buttons: [
                        BarButton(
                          key: const Key('gallery'),
                          icon: Icons.photo_library_outlined,
                          label: 'Galeria',
                          onPressed: () {},
                        ),
                        BarButton(
                          key: const Key('freeze'),
                          icon: Icons.pause,
                          label: 'Congelar',
                          primary: true,
                          flex: 1.4,
                          onPressed: () {},
                        ),
                        BarButton(
                          key: const Key('torch'),
                          icon: Icons.flashlight_on_outlined,
                          label: 'Lanterna',
                          selected: false,
                          onPressed: () {},
                        ),
                      ],
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

void main() {
  const screens = {
    'iPhone SE 375x667': Size(375, 667),
    'Android 360x640': Size(360, 640),
  };
  final controls = [
    find.byKey(const Key('freeze')),
    find.byKey(const Key('torch')),
    find.byKey(const Key('gallery')),
    find.byType(Slider),
  ];

  for (final MapEntry(key: name, value: size) in screens.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$name, texto ${scale}x: botões fixos e dentro da tela', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final result = ValueNotifier<(ColorDescription, Set<SampleWarning>)>((
          short,
          const {},
        ));
        await tester.pumpWidget(_Harness(result));
        expect(tester.takeException(), isNull);
        final before = [for (final f in controls) tester.getRect(f)];

        result.value = (long, allWarnings);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'sem estouro');
        final after = [for (final f in controls) tester.getRect(f)];

        expect(after, before, reason: 'os botões não podem se mexer');
        final screen = Offset.zero & size;
        for (final r in after) {
          expect(
            screen.contains(r.topLeft) &&
                screen.contains(r.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason: '$r fora da tela $size',
          );
        }

        // Volta para o curto: tudo no mesmo lugar.
        result.value = (short, const {});
        await tester.pump();
        expect([for (final f in controls) tester.getRect(f)], before);
      });
    }
  }

  testWidgets('no tamanho normal o cartão cabe sem rolar (iPhone SE)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_Harness(ValueNotifier((long, allWarnings))));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ResultPanel),
        matching: find.byType(Scrollable),
      ),
    );
    // ignore: avoid_print
    print('rolagem do cartão no SE: ${scrollable.position.maxScrollExtent}');
    expect(scrollable.position.maxScrollExtent, 0);
  });

  // Nome da família nunca com reticências: todos os pares "entre X e Y" e
  // todas as famílias sozinhas, com a descrição mais longa e os 4 avisos.
  final cases = <ColorDescription>[
    for (final a in ColorFamily.values)
      for (final b in [null, ...ColorFamily.values.where((x) => x != a)])
        ColorDescription(
          color: Oklab.fromHex('#B44B3C'),
          family: a,
          secondFamily: b,
          lightness: Lightness.muitoClaro,
          saturation: Saturation.acinzentado,
          undertone: b == null ? ColorFamily.verde : null,
          popularName: 'vermelho-alaranjado',
          closeness: NameCloseness.parecido,
          familyScores: const {},
        ),
  ];

  for (final MapEntry(key: name, value: size) in screens.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        '$name, texto ${scale}x: nome da família inteiro em ${cases.length} casos',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final result = ValueNotifier<(ColorDescription, Set<SampleWarning>)>((
            short,
            const {},
          ));
          await tester.pumpWidget(_Harness(result));
          final before = [for (final f in controls) tester.getRect(f)];
          var twoLines = 0;
          for (final c in cases) {
            result.value = (c, allWarnings);
            await tester.pump();
            expect(tester.takeException(), isNull);
            final p = tester.renderObject<RenderParagraph>(
              find.byKey(const Key('family-headline')),
            );
            expect(
              p.didExceedMaxLines,
              isFalse,
              reason: '${c.family} / ${c.secondFamily} cortado',
            );
            if ((p.text.style?.fontSize ?? 0) == Txt.familyMinSize &&
                p.size.height > 40) {
              twoLines++;
            }
            expect(
              [for (final f in controls) tester.getRect(f)],
              before,
              reason: 'botões mexeram em ${c.family} / ${c.secondFamily}',
            );
          }
          // ignore: avoid_print
          print('$name ${scale}x: $twoLines de ${cases.length} em 2 linhas');
        },
      );
    }
  }
}
