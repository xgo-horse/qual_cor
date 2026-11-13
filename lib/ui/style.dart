import 'package:material_ui/material_ui.dart';

/// Estilo "cartela de tinta": fundo cinza neutro e quente (para não puxar a
/// percepção da cor medida), branco nos cartões, quase preto nas ações, sem
/// nenhuma outra cor de destaque.
abstract final class Palette {
  /// Fundo de todas as telas.
  static const ground = Color(0xFFE9E8E4);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1E1E1C);
  static const textSecondary = Color(0xFF3A3A36);

  /// Rótulos e textos discretos. A especificação pedia #6B6A64, mas ele dá
  /// só 4,4:1 sobre o fundo; este dá 5,0:1 sobre o fundo e 6,1:1 no branco.
  static const muted = Color(0xFF63625C);
  static const hairline = Color(0xFFCFCDC6);
  static const hairlineLight = Color(0xFFE2E1DC);
  static const disabled = Color(0xFFA8A69F);

  static const cardShadow = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 8), blurRadius: 24),
  ];
}

/// Fontes embutidas em assets/fonts (nada é baixado): Fraunces (nome da
/// cor), Inter (interface), JetBrains Mono (código hex). São fontes
/// variáveis: o peso vai também como FontVariation('wght'), senão algumas
/// plataformas mostram sempre o peso padrão.
abstract final class Txt {
  static TextStyle _font(
    String family, {
    required double size,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    Color color = Palette.text,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: family,
    color: color,
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
    Color color = Palette.text,
    double? height,
  }) => _font(
    'Fraunces',
    size: size,
    weight: weight,
    style: style,
    color: color,
    height: height,
  );

  static TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = Palette.text,
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

  static TextStyle mono({required double size, Color color = Palette.muted}) =>
      _font(
        'JetBrains Mono',
        size: size,
        weight: FontWeight.w500,
        color: color,
      );

  /// Rótulo pequeno em caixa alta ("FAMÍLIA", "ÁREA").
  static TextStyle label({Color color = Palette.muted}) => sans(
    size: 11,
    weight: FontWeight.w600,
    color: color,
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
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.text,
        brightness: Brightness.light,
      ).copyWith(
        primary: Palette.text,
        onPrimary: Colors.white,
        secondary: Palette.textSecondary,
        onSecondary: Colors.white,
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
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.ground,
      foregroundColor: Palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: Txt.sans(size: 17, weight: FontWeight.w600),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Palette.text,
      inactiveTrackColor: Palette.hairline,
      thumbColor: Palette.text,
      overlayColor: Color(0x1F1E1E1C),
      trackHeight: 2,
      valueIndicatorColor: Palette.text,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.text,
      contentTextStyle: Txt.sans(size: 14, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.surface,
      shape: RoundedRectangleBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.text,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(),
        textStyle: Txt.sans(size: 15, weight: FontWeight.w600),
      ),
    ),
  );
}
