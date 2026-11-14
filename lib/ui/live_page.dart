import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:material_ui/material_ui.dart';

import '../camera/frame_mapper.dart';
import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../color/live_smoother.dart';
import '../color/pixel_area.dart';
import '../l10n/generated/app_localizations.dart';
import 'about_page.dart';
import 'frame.dart';
import 'photo_page.dart';
import 'result_panel.dart';
import 'style.dart';
import 'themed_texts.dart';

/// Mira ao vivo: câmera com uma mira no centro, amostrada até ~20 vezes por
/// segundo, com suavização adaptativa ([LiveSmoother]). A amostragem custa
/// menos de 0,1 ms por quadro, então roda direto na thread da interface.
class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with WidgetsBindingObserver {
  /// Intervalo mínimo entre amostras (~20 por segundo). A câmera manda ~30
  /// quadros/s; os que chegam antes disso são ignorados.
  static const _minInterval = Duration(milliseconds: 50);

  final _sampler = const AreaSampler();
  final _smoother = LiveSmoother(ColorNamer());

  /// Só o painel de resultado escuta isto; a prévia da câmera não é
  /// reconstruída a cada amostra.
  final _result = ValueNotifier<_LiveResult?>(null);

  CameraController? _controller;
  String? _error;
  bool _permissionDenied = false;
  bool _initializing = false;
  bool _frozen = false;
  bool _torch = false;
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  double _areaFraction = 0.04;

  /// Último quadro recebido. Ao congelar, vira [_frozenImage] e a mira pode
  /// ser arrastada por ele; [_frozenPoint] é a posição da mira em pixels do
  /// quadro.
  CameraImage? _lastImage;
  CameraImage? _frozenImage;
  Offset? _frozenPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Depois do primeiro quadro, para poder ler as localizações do context.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _result.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final c = _controller;
      _controller = null;
      _torch = false;
      c?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (_initializing) return;
    _initializing = true;
    final l10n = AppLocalizations.of(context);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = l10n.liveNoCamera;
          _permissionDenied = false;
        });
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      if (_frozen) await controller.pausePreview();
      setState(() {
        _controller = controller;
        _error = null;
        _permissionDenied = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied =
          e.code.contains('AccessDenied') || e.code.contains('Restricted');
      setState(() {
        _permissionDenied = denied;
        _error = denied
            ? l10n.cameraPermissionDenied
            : l10n.cameraError(e.description ?? e.code);
      });
    } finally {
      _initializing = false;
    }
  }

  void _onFrame(CameraImage image) {
    if (_frozen || !mounted) return;
    _lastImage = image;
    final now = DateTime.now();
    if (now.difference(_lastSample) < _minInterval) return;
    _lastSample = now;
    final result = _sampler.sample(
      _pixelsAt(image, image.width ~/ 2, image.height ~/ 2),
    );
    if (result == null) return;
    final changed = _smoother.add(result.color);
    final shown = _smoother.shown;
    final prev = _result.value;
    if (shown != null &&
        (changed ||
            prev == null ||
            !setEquals(prev.warnings, result.warnings))) {
      _result.value = _LiveResult(shown, result.warnings);
    }
  }

  /// Raio da área em pixels do quadro.
  int _frameRadius(CameraImage image) => math.max(
    2,
    (math.min(image.width, image.height) * _areaFraction).round(),
  );

  List<int> _pixelsAt(CameraImage image, int cx, int cy) {
    final w = image.width, h = image.height;
    final radius = _frameRadius(image);
    if (image.format.group == ImageFormatGroup.bgra8888) {
      final p = image.planes.first;
      return pixelsFromBgra8888(
        width: w,
        height: h,
        bytes: p.bytes,
        bytesPerRow: p.bytesPerRow,
        cx: cx,
        cy: cy,
        radius: radius,
      );
    }
    if (image.planes.length < 3) return const [];
    final y = image.planes[0], u = image.planes[1], v = image.planes[2];
    return pixelsFromYuv420(
      width: w,
      height: h,
      yPlane: y.bytes,
      yRowStride: y.bytesPerRow,
      uPlane: u.bytes,
      vPlane: v.bytes,
      uvRowStride: u.bytesPerRow,
      uvPixelStride: u.bytesPerPixel ?? 1,
      cx: cx,
      cy: cy,
      radius: radius,
    );
  }

  Future<void> _toggleFreeze() async {
    final c = _controller;
    final freezing = !_frozen;
    final image = _lastImage;
    HapticFeedback.selectionClick();
    setState(() {
      _frozen = freezing;
      if (freezing && image != null) {
        _frozenImage = image;
        _frozenPoint = Offset(image.width / 2, image.height / 2);
      } else {
        // Continuar: volta ao vivo com a mira no centro.
        _frozenImage = null;
        _frozenPoint = null;
        _smoother.reset();
      }
    });
    if (c == null) return;
    try {
      if (freezing) {
        await c.pausePreview();
      } else {
        await c.resumePreview();
      }
    } on CameraException catch (_) {}
  }

  /// Quanto o quadro do stream precisa girar (sentido horário) para ficar
  /// como a prévia aparece. O Android entrega na orientação do sensor; o
  /// plugin do iOS já entrega em pé.
  int _rotationFor(CameraImage image) {
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final frameIsPortrait = image.height > image.width;
    if (portrait == frameIsPortrait) return 0;
    return Platform.isAndroid
        ? (_controller?.description.sensorOrientation ?? 90)
        : 90;
  }

  /// Amostra o quadro congelado no ponto [framePoint] (pixels do quadro),
  /// sem suavização: o resultado aparece na hora enquanto a mira é arrastada.
  void _sampleFrozen(Offset framePoint) {
    final image = _frozenImage;
    if (image == null) return;
    final result = _sampler.sample(
      _pixelsAt(image, framePoint.dx.round(), framePoint.dy.round()),
    );
    setState(() => _frozenPoint = framePoint);
    if (result == null) return;
    _result.value = _LiveResult(
      _smoother.namer.describe(result.color),
      result.warnings,
    );
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    final next = !_torch;
    try {
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torch = next);
    } on CameraException catch (_) {}
  }

  /// Para a câmera enquanto outra tela está por cima e religa na volta.
  Future<void> _pushPaused(Widget page) async {
    final c = _controller;
    setState(() {
      _controller = null;
      _torch = false;
    });
    await c?.dispose();
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted && _controller == null) await _start();
  }

  Future<void> _openGallery() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.homeGallery, style: Txt.sans(size: 16)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            Divider(height: 1, color: Palette.hairlineLight),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.homeTakePhoto, style: Txt.sans(size: 16)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pushPaused(PhotoPage(source: source));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    final frozen = _frozenImage != null;

    return Scaffold(
      body: SafeArea(
        // A câmera ocupa sempre a metade de cima; resultado e controles, a
        // de baixo.
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CameraFrame(
                  frozen: frozen,
                  frozenLabel: l10n.tFrozenChip,
                  trailing: InfoButton(
                    onPressed: () => _pushPaused(const AboutPage()),
                  ),
                  child: _error != null
                      ? StatusMessage(
                          icon: _permissionDenied
                              ? Icons.no_photography_outlined
                              : Icons.videocam_off_outlined,
                          text: _error!,
                          actionLabel: _permissionDenied
                              ? l10n.openSettings
                              : l10n.retry,
                          onAction: _permissionDenied
                              ? () => AppSettings.openAppSettings()
                              : _start,
                        )
                      : controller == null || !controller.value.isInitialized
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : _CoverPreview(
                          controller: controller,
                          areaFraction: _areaFraction,
                          frozen: _frozenImage == null
                              ? null
                              : _Frozen(
                                  width: _frozenImage!.width,
                                  height: _frozenImage!.height,
                                  rotation: _rotationFor(_frozenImage!),
                                  mirror:
                                      controller.description.lensDirection ==
                                      CameraLensDirection.front,
                                  point: _frozenPoint!,
                                  radius: _frameRadius(_frozenImage!)
                                      .toDouble(),
                                ),
                          onFrozenPoint: _sampleFrozen,
                        ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<_LiveResult?>(
                valueListenable: _result,
                builder: (context, result, _) => ResultPanel(
                  description: result?.description,
                  warnings: result?.warnings ?? const {},
                  note: frozen ? l10n.liveDragHint : null,
                  areaFraction: _areaFraction,
                  onAreaChanged: (v) {
                    setState(() => _areaFraction = v);
                    final p = _frozenPoint;
                    if (_frozenImage != null && p != null) _sampleFrozen(p);
                  },
                  bar: BottomBar(
                    buttons: [
                      BarButton(
                        key: const Key('gallery'),
                        icon: Icons.photo_library_outlined,
                        label: l10n.tBarGallery,
                        onPressed: _openGallery,
                      ),
                      BarButton(
                        key: const Key('freeze'),
                        icon: _frozen ? Icons.play_arrow : Icons.pause,
                        label: _frozen ? l10n.tContinue : l10n.tFreeze,
                        primary: true,
                        flex: 1.4,
                        onPressed: controller == null ? null : _toggleFreeze,
                      ),
                      BarButton(
                        key: const Key('torch'),
                        icon: _torch
                            ? Icons.flashlight_on
                            : Icons.flashlight_on_outlined,
                        label: l10n.barTorch,
                        tooltip: _torch ? l10n.torchOffHint : l10n.torchOnHint,
                        selected: _torch,
                        onPressed: controller == null ? null : _toggleTorch,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveResult {
  const _LiveResult(this.description, this.warnings);

  final ColorDescription description;
  final Set<SampleWarning> warnings;
}

/// Dados da imagem congelada, para posicionar e mover a mira.
class _Frozen {
  const _Frozen({
    required this.width,
    required this.height,
    required this.rotation,
    required this.mirror,
    required this.point,
    required this.radius,
  });

  final int width, height, rotation;
  final bool mirror;

  /// Mira e raio em pixels do quadro.
  final Offset point;
  final double radius;
}

/// Prévia da câmera preenchendo todo o espaço (corta as sobras, sem
/// distorcer), com a mira. Ao vivo a mira fica no centro; com a imagem
/// congelada ([frozen]) ela pode ser tocada/arrastada para qualquer ponto.
/// O raio da mira acompanha a escala do corte, para mostrar exatamente a
/// área que é lida no quadro.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.controller,
    required this.areaFraction,
    required this.frozen,
    required this.onFrozenPoint,
  });

  final CameraController controller;
  final double areaFraction;
  final _Frozen? frozen;
  final ValueChanged<Offset> onFrozenPoint;

  @override
  Widget build(BuildContext context) {
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    // value.aspectRatio é largura/altura do quadro do sensor (deitado).
    final frameAspect = portrait
        ? 1 / controller.value.aspectRatio
        : controller.value.aspectRatio;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final pw = w, ph = w / frameAspect;
        final preview = ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: pw,
              height: ph,
              child: CameraPreview(controller),
            ),
          ),
        );

        final f = frozen;
        if (f == null) {
          final scale = math.max(w / pw, h / ph);
          final radius = math.max(6.0, math.min(pw, ph) * scale * areaFraction);
          return Stack(
            fit: StackFit.expand,
            children: [
              preview,
              _Crosshair(radius: radius),
            ],
          );
        }

        final mapper = FrameMapper(
          frameWidth: f.width,
          frameHeight: f.height,
          rotation: f.rotation,
          displayAspect: frameAspect,
          viewSize: Size(w, h),
          mirror: f.mirror,
        );
        void move(Offset local) => onFrozenPoint(
          mapper.clampFrame(mapper.viewToFrame(local), f.radius),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => move(d.localPosition),
          onPanStart: (d) => move(d.localPosition),
          onPanUpdate: (d) => move(d.localPosition),
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              _Crosshair(
                radius: math.max(6.0, f.radius * mapper.scale),
                center: mapper.frameToView(f.point),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mira desenhada sobre a prévia. O círculo mostra a área amostrada.
class _Crosshair extends StatelessWidget {
  const _Crosshair({required this.radius, this.center});

  final double radius;

  /// Centro da mira; null = centro da prévia.
  final Offset? center;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).tCrosshairLabel,
      child: CustomPaint(painter: _CrosshairPainter(radius, center)),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(this.radius, this.center);

  /// Modo Warhammer na hora de desenhar (a cor da mira muda).
  final bool grim = Palette.grim;

  final double radius;
  final Offset? center;

  @override
  void paint(Canvas canvas, Size size) {
    paintCrosshair(canvas, center ?? size.center(Offset.zero), radius);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) =>
      old.radius != radius || old.center != center || old.grim != grim;
}
