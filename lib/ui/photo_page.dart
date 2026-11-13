import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../color/pixel_area.dart';
import '../l10n/generated/app_localizations.dart';
import 'frame.dart';
import 'result_panel.dart';

/// Lado maior máximo da foto em memória. Fotos de celular têm 12+ MP; para
/// achar a cor de uma área isso basta e deixa tudo rápido.
const int _maxSide = 1600;

/// Decodifica, aplica a orientação do EXIF e reduz. Roda em outro isolate
/// (compute), uma vez por foto: uma foto de 12 MP leva ~0,5 s e travaria a
/// tela (ver test/bench/photo_decode_test.dart).
img.Image? decodeForSampling(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  final longest = math.max(image.width, image.height);
  if (longest > _maxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: _maxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: _maxSide,
            interpolation: img.Interpolation.average,
          );
  }
  return image.convert(format: img.Format.uint8, numChannels: 4);
}

Future<ui.Image> _toUiImage(img.Image image) {
  final rgba = image.getBytes(order: img.ChannelOrder.rgba);
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    image.width,
    image.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Onde a imagem fica dentro da caixa com BoxFit.contain (centralizada) e
/// a conversão de um toque na tela para o pixel da imagem.
class ContainLayout {
  ContainLayout(this.imageSize, Size box)
    : dest = Alignment.center.inscribe(
        applyBoxFit(BoxFit.contain, imageSize, box).destination,
        Offset.zero & box,
      );

  final Size imageSize;
  final Rect dest;

  double get scale => dest.width / imageSize.width;

  /// Pixel da imagem sob [local], ou null se o toque caiu fora da imagem
  /// (nas faixas pretas).
  Offset? toImage(Offset local) {
    if (!dest.contains(local)) return null;
    final p = (local - dest.topLeft) / scale;
    return Offset(
      p.dx.clamp(0, imageSize.width - 1),
      p.dy.clamp(0, imageSize.height - 1),
    );
  }

  /// Posição na tela de um pixel da imagem (para desenhar o marcador).
  Offset toLocal(Offset imagePoint) => dest.topLeft + imagePoint * scale;
}

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key, required this.source});

  final ImageSource source;

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final _sampler = const AreaSampler();
  final _namer = ColorNamer();

  img.Image? _image;
  ui.Image? _uiImage;
  bool _loading = true;
  bool _failed = false;
  double _areaFraction = 0.03;

  /// Ponto escolhido, em pixels da imagem.
  Offset? _point;
  ColorDescription? _description;
  Set<SampleWarning> _warnings = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pick(widget.source));
  }

  @override
  void dispose() {
    _uiImage?.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (!mounted) return;
      if (file == null) {
        // Cancelou sem nenhuma foto aberta: volta para o início.
        if (_image == null) {
          Navigator.of(context).pop();
        } else {
          setState(() => _loading = false);
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final image = await compute(decodeForSampling, bytes);
      if (image == null) throw const FormatException('decode');
      final uiImage = await _toUiImage(image);
      if (!mounted) {
        uiImage.dispose();
        return;
      }
      setState(() {
        _uiImage?.dispose();
        _image = image;
        _uiImage = uiImage;
        _point = null;
        _description = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _image == null;
      });
    }
  }

  int _radiusPx(img.Image image) => math.max(
    2,
    (math.min(image.width, image.height) * _areaFraction).round(),
  );

  void _sampleAt(Offset point) {
    final image = _image;
    if (image == null) return;
    final pixels = pixelsFromImage(
      image,
      point.dx.round(),
      point.dy.round(),
      _radiusPx(image),
    );
    final result = _sampler.sample(pixels);
    setState(() {
      _point = point;
      if (result != null) {
        _description = _namer.describe(result.color);
        _warnings = result.warnings;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uiImage = _uiImage;

    return Scaffold(
      body: SafeArea(
        // Mesmo layout da mira: foto na metade de cima, resultado embaixo.
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CameraFrame(
                  child: _loading
                      ? StatusMessage(
                          icon: Icons.hourglass_empty,
                          text: l10n.photoLoading,
                        )
                      : uiImage == null
                      ? StatusMessage(
                          icon: Icons.broken_image_outlined,
                          text: _failed ? l10n.photoError : '',
                          actionLabel: l10n.retry,
                          onAction: () => _pick(widget.source),
                        )
                      : _TappableImage(
                          image: uiImage,
                          point: _point,
                          radiusPx: _radiusPx(_image!).toDouble(),
                          onPoint: _sampleAt,
                        ),
                ),
              ),
            ),
            Expanded(
              child: ResultPanel(
                description: _description,
                warnings: _warnings,
                placeholder: l10n.photoTapHint,
                areaFraction: _areaFraction,
                onAreaChanged: (v) {
                  setState(() => _areaFraction = v);
                  final p = _point;
                  if (p != null) _sampleAt(p);
                },
                bar: BottomBar(
                  buttons: [
                    BarButton(
                      key: const Key('back'),
                      icon: Icons.center_focus_strong_outlined,
                      label: l10n.barBack,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    BarButton(
                      key: const Key('another'),
                      icon: Icons.photo_library_outlined,
                      label: l10n.barAnotherPhoto,
                      primary: true,
                      flex: 1.4,
                      onPressed: _loading
                          ? null
                          : () => _pick(ImageSource.gallery),
                    ),
                    BarButton(
                      key: const Key('camera'),
                      icon: Icons.photo_camera_outlined,
                      label: l10n.barTakePhoto,
                      onPressed: _loading
                          ? null
                          : () => _pick(ImageSource.camera),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra a foto inteira (BoxFit.contain) e converte o toque em
/// coordenadas da imagem.
class _TappableImage extends StatelessWidget {
  const _TappableImage({
    required this.image,
    required this.point,
    required this.radiusPx,
    required this.onPoint,
  });

  final ui.Image image;
  final Offset? point;
  final double radiusPx;
  final ValueChanged<Offset> onPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());
        final layout = ContainLayout(imageSize, box.biggest);
        final dest = layout.dest;
        final scale = layout.scale;

        void handle(Offset local) {
          final p = layout.toImage(local);
          if (p != null) onPoint(p);
        }

        final pt = point;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: dest,
                child: Semantics(
                  image: true,
                  label: l10n.photoTapHint,
                  child: RawImage(image: image, fit: BoxFit.fill),
                ),
              ),
              if (pt != null)
                Positioned.fill(
                  child: Semantics(
                    label: l10n.markerLabel,
                    child: CustomPaint(
                      painter: _MarkerPainter(
                        center: layout.toLocal(pt),
                        radius: math.max(8, radiusPx * scale),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) =>
      paintCrosshair(canvas, center, radius);

  @override
  bool shouldRepaint(_MarkerPainter old) =>
      old.center != center || old.radius != radius;
}
