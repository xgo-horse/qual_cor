import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/color/color_namer.dart';
import 'package:qual_cor/color/color_names_pt.dart';
import 'package:qual_cor/color/oklab.dart';

void main() {
  final namer = ColorNamer();
  ColorDescription d(String hex) => namer.describe(Oklab.fromHex(hex));

  group('nível 1: família', () {
    final cases = {
      '#FF0000': ColorFamily.vermelho,
      '#000080': ColorFamily.azul,
      '#808080': ColorFamily.cinza,
      '#8B4513': ColorFamily.marrom,
      '#FFC0CB': ColorFamily.rosa,
      '#FFFFFF': ColorFamily.branco,
      '#000000': ColorFamily.preto,
      '#FFFF00': ColorFamily.amarelo,
      '#FF8000': ColorFamily.laranja,
      '#008000': ColorFamily.verde,
      '#800080': ColorFamily.roxo,
      '#0000FF': ColorFamily.azul,
      '#C0C0C0': ColorFamily.cinza,
      '#800020': ColorFamily.vermelho,
    };
    cases.forEach((hex, family) {
      test('$hex é $family', () {
        final r = d(hex);
        expect(r.family, family);
        expect(r.isAmbiguous, isFalse);
      });
    });
  });

  test('#000080: azul escuro, parecido com azul-marinho', () {
    final r = d('#000080');
    expect(r.lightness, anyOf(Lightness.escuro, Lightness.muitoEscuro));
    expect(r.popularName, 'azul-marinho');
    expect(r.closeness, NameCloseness.parecido);
  });

  test('#008080 fica entre verde e azul (ou vira azul-petróleo)', () {
    final r = d('#008080');
    final families = {r.family, r.secondFamily, r.undertone};
    final betweenGreenBlue =
        families.contains(ColorFamily.verde) &&
        families.contains(ColorFamily.azul);
    expect(betweenGreenBlue || r.popularName == 'azul-petróleo', isTrue);
  });

  test('cor entre duas famílias vira "entre X e Y"', () {
    final r = d('#EE82EE'); // violeta claro: roxo ou rosa
    expect(r.isAmbiguous, isTrue);
    expect({r.family, r.secondFamily}, {ColorFamily.roxo, ColorFamily.rosa});
    expect(r.undertone, isNull);
  });

  test('nível 2: claridade relativa à família', () {
    expect(d('#FF0000').lightness, isNull);
    expect(
      d('#800000').lightness,
      anyOf(Lightness.escuro, Lightness.muitoEscuro),
    );
    expect(
      d('#C0C0C0').lightness,
      anyOf(Lightness.claro, Lightness.muitoClaro),
    );
    expect(
      d('#404040').lightness,
      anyOf(Lightness.escuro, Lightness.muitoEscuro),
    );
    // preto e branco não recebem claro/escuro
    expect(d('#000000').lightness, isNull);
    expect(d('#FFFFFF').lightness, isNull);
  });

  test('nível 2: saturação', () {
    expect(d('#FF0000').saturation, Saturation.vivo);
    expect(
      d('#8FBC8F').saturation,
      anyOf(Saturation.suave, Saturation.acinzentado),
    );
    expect(d('#808080').saturation, isNull); // neutros não têm saturação
  });

  test('nível 2: subtom de cor cromática', () {
    final r = d('#A52A2A'); // vermelho amarronzado
    expect(r.family, ColorFamily.vermelho);
    expect(r.undertone, ColorFamily.marrom);
  });

  test('nível 2: cinza com subtom azulado', () {
    final r = d('#708090');
    expect(r.family, ColorFamily.cinza);
    expect(r.undertone, ColorFamily.azul);
    // cinza neutro não tem subtom
    expect(d('#808080').undertone, isNull);
  });

  test(
    'nível 3: "Parecido com" perto, "Lembra" a meia distância, nada longe',
    () {
      expect(d('#FF0000').closeness, NameCloseness.parecido);
      // Lista com um nome só, para medir a distância sem vizinhos no meio.
      final tiny = ColorNamer(
        names: [NamedColor('vermelho', '#FF0000', ColorFamily.vermelho)],
        k: 1,
      );
      final ref = Oklab.fromHex('#FF0000');
      final near = tiny.describe(Oklab(ref.l - 0.02, ref.a, ref.b));
      expect(near.closeness, NameCloseness.parecido);
      final medium = tiny.describe(Oklab(ref.l - 0.05, ref.a, ref.b));
      expect(medium.closeness, NameCloseness.lembra);
      expect(medium.popularName, 'vermelho');
      final far = tiny.describe(Oklab.fromHex('#7F0000'));
      expect(far.popularName, isNull);
      expect(far.closeness, isNull);
    },
  );

  test('textKey muda quando o texto muda', () {
    expect(d('#FF0000').textKey, isNot(d('#000080').textKey));
    expect(d('#FF0000').textKey, d('#FE0000').textKey);
  });

  test(
    'lista de nomes: ~150+ nomes, todas as famílias, sem nomes repetidos',
    () {
      expect(colorNamesPt.length, greaterThanOrEqualTo(150));
      expect(
        colorNamesPt.map((n) => n.family).toSet(),
        ColorFamily.values.toSet(),
      );
      final names = colorNamesPt.map((n) => n.name).toList();
      expect(names.toSet().length, names.length);
      for (final n in [
        'bordô',
        'vinho',
        'azul-marinho',
        'azul-petróleo',
        'verde-musgo',
        'verde-oliva',
        'bege',
        'creme',
        'salmão',
        'mostarda',
        'turquesa',
        'lilás',
        'terracota',
        'caramelo',
        'cor de vinho',
        'grafite',
        'chumbo',
        'off-white',
      ]) {
        expect(names, contains(n));
      }
    },
  );

  test(
    'cada nome da lista é reconhecido na própria família (consistência)',
    () {
      var wrong = 0;
      for (final n in colorNamesPt) {
        final r = namer.describe(n.lab);
        if (r.family != n.family && r.secondFamily != n.family) wrong++;
      }
      // Nomes de fronteira podem cair na vizinha; a grande maioria não.
      expect(wrong / colorNamesPt.length, lessThan(0.08));
    },
  );
}
