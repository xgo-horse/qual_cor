import 'package:material_ui/material_ui.dart';

import '../warhammer_mode.dart';

/// Estilo "cartela de tinta": fundo cinza neutro e quente (para não puxar a
/// percepção da cor medida), branco nos cartões, quase preto nas ações, sem
/// nenhuma outra cor de destaque.
///
/// Com o Modo Warhammer ligado ([warhammer]), as mesmas funções devolvem a
/// paleta "grimdark": preto e grafite, pergaminho no texto, dourado
/// envelhecido nos filetes e vermelho-sangue na ação principal. Por isso são
/// getters, não constantes; ao trocar de modo o app reconstrói tudo.
abstract final class Palette {
  static bool get grim => warhammer.enabled;

  /// Fundo de todas as telas.
  static Color get ground => grim ? Grim.black : _ground;
  static Color get surface => grim ? Grim.graphite : _surface;
  static Color get text => grim ? Grim.parchment : _text;
  static Color get textSecondary => grim ? Grim.parchmentDim : _textSecondary;

  /// Rótulos e textos discretos. A especificação pedia #6B6A64, mas ele dá
  /// só 4,4:1 sobre o fundo; este dá 5,0:1 sobre o fundo e 6,1:1 no branco.
  static Color get muted => grim ? Grim.gold : _muted;
  static Color get hairline => grim ? Grim.goldDark : _hairline;
  static Color get hairlineLight => grim ? Grim.line : _hairlineLight;
  static Color get disabled => grim ? Grim.ash : _disabled;

  /// Fundo e texto da ação principal (Congelar).
  static Color get primary => grim ? Grim.blood : _text;
  static Color get onPrimary => grim ? Grim.parchment : _surface;

  static const _ground = Color(0xFFE9E8E4);
  static const _surface = Color(0xFFFFFFFF);
  static const _text = Color(0xFF1E1E1C);
  static const _textSecondary = Color(0xFF3A3A36);
  static const _muted = Color(0xFF63625C);
  static const _hairline = Color(0xFFCFCDC6);
  static const _hairlineLight = Color(0xFFE2E1DC);
  static const _disabled = Color(0xFFA8A69F);

  static List<BoxShadow> get cardShadow => grim ? Grim.cardShadow : _shadow;
  static const _shadow = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  /// Borda do cartão (só no Modo Warhammer: filete dourado).
  static Border? get cardBorder =>
      grim ? Border.all(color: Grim.goldDark) : null;
}

/// Cores do Modo Warhammer. Contrastes (texto sobre [graphite]):
/// pergaminho 12:1, pergaminho escuro 9:1, dourado 5,6:1.
abstract final class Grim {
  static const black = Color(0xFF0E0D0B);
  static const graphite = Color(0xFF1C1A17);
  static const parchment = Color(0xFFE9DDBF);
  static const parchmentDim = Color(0xFFCDBF9C);
  static const gold = Color(0xFFC09A4A);
  static const goldDark = Color(0xFF6E5A2E);
  static const line = Color(0xFF3A342A);
  static const ash = Color(0xFF6B6354);
  static const blood = Color(0xFF8E1B16);
  static const cardShadow = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 10),
  ];
}

/// Fontes embutidas em assets/fonts (nada é baixado): Fraunces (nome da
/// cor; Cinzel no Modo Warhammer), Inter (interface), JetBrains Mono
/// (código hex). São fontes
/// variáveis: o peso vai também como FontVariation('wght'), senão algumas
/// plataformas mostram sempre o peso padrão.
abstract final class Txt {
  static TextStyle _font(
    String family, {
    required double size,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: family,
    color: color ?? Palette.text,
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    // 0 explícito: senão herda o espaçamento do tema (0,25 no corpo) e as
    // medições de largura deixam de bater com o que é desenhado.
    letterSpacing: letterSpacing ?? 0,
    height: height,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

  static TextStyle serif({
    required double size,
    FontWeight weight = FontWeight.w600,
    FontStyle style = FontStyle.normal,
    Color? color,
    double? height,
  }) => _font(
    // Modo Warhammer: Cinzel, capitulares romanas gravadas (sem itálico).
    Palette.grim ? 'Cinzel' : 'Fraunces',
    size: size,
    weight: weight,
    style: Palette.grim ? FontStyle.normal : style,
    color: color,
    height: height,
  );

  static TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => _font(
    'Inter',
    size: size,
    weight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle mono({required double size, Color? color}) => _font(
    'JetBrains Mono',
    size: size,
    weight: FontWeight.w500,
    color: color ?? Palette.muted,
  );

  /// Rótulo pequeno em caixa alta ("FAMÍLIA", "ÁREA").
  static TextStyle label({Color? color}) => sans(
    size: 11,
    weight: FontWeight.w600,
    color: color ?? Palette.muted,
    letterSpacing: 11 * 0.14,
  );

  /// Nome da família da cor (encolhe até [familyMinSize] para caber).
  static const double familySize = 38;
  static const double familyMinSize = 26;
  static TextStyle family({double size = familySize}) =>
      serif(size: size, height: 1.05);

  /// Nome popular ("azul-petróleo").
  static TextStyle popular() =>
      serif(size: 15, weight: FontWeight.w500, style: FontStyle.italic);

  static TextStyle description() =>
      sans(size: 15, color: Palette.textSecondary, height: 1.3);

  static TextStyle warning() => sans(size: 13, color: Palette.muted);
}

ThemeData buildTheme() {
  final grim = Palette.grim;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.text,
        brightness: grim ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: Palette.primary,
        onPrimary: Palette.onPrimary,
        secondary: Palette.textSecondary,
        onSecondary: Palette.surface,
        surface: Palette.ground,
        onSurface: Palette.text,
        surfaceContainerHighest: Palette.surface,
        outline: Palette.hairline,
        outlineVariant: Palette.hairlineLight,
      );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final body = Txt.sans(size: 15);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.ground,
    textTheme: base.textTheme.apply(
      fontFamily: body.fontFamily,
      bodyColor: Palette.text,
      displayColor: Palette.text,
    ),
    iconTheme: IconThemeData(color: Palette.text),
    listTileTheme: ListTileThemeData(iconColor: Palette.text),
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.ground,
      foregroundColor: Palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: grim
          ? Txt.serif(size: 18, weight: FontWeight.w700)
          : Txt.sans(size: 17, weight: FontWeight.w600),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: grim ? Palette.muted : Palette.text,
      inactiveTrackColor: Palette.hairline,
      thumbColor: grim ? Palette.muted : Palette.text,
      overlayColor: Palette.text.withValues(alpha: 0.12),
      trackHeight: 2,
      valueIndicatorColor: Palette.text,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Palette.onPrimary
            : Palette.disabled,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Palette.primary
            : Palette.hairlineLight,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: grim ? Palette.surface : Palette.text,
      contentTextStyle: Txt.sans(
        size: 14,
        color: grim ? Palette.text : Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: grim
          ? RoundedRectangleBorder(side: BorderSide(color: Palette.hairline))
          : const RoundedRectangleBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.onPrimary,
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(),
        textStyle: Txt.sans(size: 15, weight: FontWeight.w600),
      ),
    ),
  );
}
