import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// Converte pontos entre a tela (a prévia da câmera mostrada com corte de
/// preenchimento, "cover") e os pixels do quadro que veio do stream da
/// câmera.
///
/// - [rotation]: quanto o quadro precisa girar no sentido horário para ficar
///   como aparece na tela (0, 90, 180 ou 270). No Android, em retrato, é o
///   `sensorOrientation` (normalmente 90); no iOS o plugin já entrega o
///   quadro em pé (0).
/// - [displayAspect]: largura/altura da prévia como é mostrada (antes do
///   corte). O mapeamento usa coordenadas normalizadas da prévia, então
///   funciona mesmo se o quadro de análise tiver resolução diferente.
/// - [mirror]: câmera frontal (imagem espelhada).
class FrameMapper {
  FrameMapper({
    required this.frameWidth,
    required this.frameHeight,
    required this.rotation,
    required this.displayAspect,
    required this.viewSize,
    this.mirror = false,
  }) : assert(rotation % 90 == 0) {
    final w = viewSize.width, h = viewSize.height;
    final pw = w, ph = w / displayAspect;
    final s = math.max(w / pw, h / ph);
    _shown = Size(pw * s, ph * s);
    _origin = Offset((w - _shown.width) / 2, (h - _shown.height) / 2);
  }

  final int frameWidth;
  final int frameHeight;
  final int rotation;
  final double displayAspect;
  final Size viewSize;
  final bool mirror;

  late final Size _shown;
  late final Offset _origin;

  int get _rot => ((rotation % 360) + 360) % 360;
  bool get _swap => _rot == 90 || _rot == 270;

  /// Tamanho do quadro já girado como aparece na tela.
  double get rotatedWidth => (_swap ? frameHeight : frameWidth).toDouble();
  double get rotatedHeight => (_swap ? frameWidth : frameHeight).toDouble();

  /// Pixels de tela por pixel do quadro (menor dos dois eixos).
  double get scale =>
      math.min(_shown.width / rotatedWidth, _shown.height / rotatedHeight);

  /// Ponto da tela → pixel do quadro.
  Offset viewToFrame(Offset v) {
    var rx = (v.dx - _origin.dx) / _shown.width * rotatedWidth;
    final ry = (v.dy - _origin.dy) / _shown.height * rotatedHeight;
    if (mirror) rx = rotatedWidth - rx;
    final w = frameWidth.toDouble(), h = frameHeight.toDouble();
    return switch (_rot) {
      90 => Offset(ry, h - rx),
      180 => Offset(w - rx, h - ry),
      270 => Offset(w - ry, rx),
      _ => Offset(rx, ry),
    };
  }

  /// Pixel do quadro → ponto da tela.
  Offset frameToView(Offset f) {
    final w = frameWidth.toDouble(), h = frameHeight.toDouble();
    var (rx, ry) = switch (_rot) {
      90 => (h - f.dy, f.dx),
      180 => (w - f.dx, h - f.dy),
      270 => (f.dy, w - f.dx),
      _ => (f.dx, f.dy),
    };
    if (mirror) rx = rotatedWidth - rx;
    return Offset(
      _origin.dx + rx / rotatedWidth * _shown.width,
      _origin.dy + ry / rotatedHeight * _shown.height,
    );
  }

  /// Mantém o círculo de raio [radius] (pixels do quadro) dentro do quadro
  /// e dentro da parte visível da prévia (o corte esconde as bordas).
  Offset clampFrame(Offset f, double radius) {
    // Parte visível da tela, convertida para o quadro.
    final a = viewToFrame(Offset.zero);
    final b = viewToFrame(Offset(viewSize.width, viewSize.height));
    final minX = math.max(math.min(a.dx, b.dx), 0) + radius;
    final maxX = math.min(math.max(a.dx, b.dx), frameWidth.toDouble()) - radius;
    final minY = math.max(math.min(a.dy, b.dy), 0) + radius;
    final maxY =
        math.min(math.max(a.dy, b.dy), frameHeight.toDouble()) - radius;
    double c(double v, double lo, double hi) =>
        lo > hi ? (lo + hi) / 2 : v.clamp(lo, hi);
    return Offset(c(f.dx, minX, maxX), c(f.dy, minY, maxY));
  }
}
