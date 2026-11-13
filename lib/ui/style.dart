import 'package:google_fonts/google_fonts.dart';
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

/// Fontes: Fraunces (nome da cor), Inter (interface), JetBrains Mono
/// (código hex). Vêm do pacote google_fonts: usa a fonte embutida em
/// assets/fonts se existir; senão baixa uma vez e guarda no aparelho. Sem
/// internet e sem a fonte embutida, cai na fonte do sistema (nada quebra).
abstract final class Txt {
  /// Os testes desligam o google_fonts (sem rede) e usam a fonte padrão.
  static bool useGoogleFonts = true;

  static TextStyle _font(
    TextStyle Function({
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      FontStyle? fontStyle,
      double? letterSpacing,
      double? height,
    })
    google,
    String family, {
    required double size,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    Color color = Palette.text,
    double? letterSpacing,
    double? height,
  }) {
    if (useGoogleFonts) {
      return google(
        color: color,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return TextStyle(
      fontFamily: family,
      color: color,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle serif({
    required double size,
    FontWeight weight = FontWeight.w600,
    FontStyle style = FontStyle.normal,
    Color color = Palette.text,
    double? height,
  }) => _font(
    ({color, fontSize, fontWeight, fontStyle, letterSpacing, height}) =>
        GoogleFonts.fraunces(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
          height: height,
        ),
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
    ({color, fontSize, fontWeight, fontStyle, letterSpacing, height}) =>
        GoogleFonts.inter(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
          height: height,
        ),
    'Inter',
    size: size,
    weight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle mono({required double size, Color color = Palette.muted}) =>
      _font(
        ({color, fontSize, fontWeight, fontStyle, letterSpacing, height}) =>
            GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
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

  /// Nome da família da cor.
  static TextStyle family() => serif(size: 38, height: 1.05);

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
