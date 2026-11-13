import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../color/pixel_area.dart';
import '../l10n/generated/app_localizations.dart';
import 'frame.dart';
import 'photo_decode.dart';
import 'result_panel.dart';

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

  DecodedPhoto? _photo;
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
    _photo?.dispose();
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
        if (_photo == null) {
          Navigator.of(context).pop();
        } else {
          setState(() => _loading = false);
        }
        return;
      }
      final bytes = await file.readAsBytes();
      // Decodificador nativo do Flutter: fora da thread da interface, já
      // reduzido e com a orientação EXIF aplicada.
      final photo = await decodePhoto(bytes);
      if (!mounted) {
        photo.dispose();
        return;
      }
      setState(() {
        _photo?.dispose();
        _photo = photo;
        _point = null;
        _description = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _photo == null;
      });
    }
  }

  int _radiusPx(DecodedPhoto photo) => math.max(
    2,
    (math.min(photo.width, photo.height) * _areaFraction).round(),
  );

  void _sampleAt(Offset point) {
    final photo = _photo;
    if (photo == null) return;
    final pixels = pixelsFromRgba(
      width: photo.width,
      height: photo.height,
      bytes: photo.rgba,
      cx: point.dx.round(),
      cy: point.dy.round(),
      radius: _radiusPx(photo),
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
    final uiImage = _photo?.image;

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
                          radiusPx: _radiusPx(_photo!).toDouble(),
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
