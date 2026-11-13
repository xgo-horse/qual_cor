import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:material_ui/material_ui.dart';

import '../color/area_sampler.dart';
import '../color/color_namer.dart';
import '../color/live_smoother.dart';
import '../color/pixel_area.dart';
import '../l10n/generated/app_localizations.dart';
import 'area_slider.dart';
import 'result_card.dart';

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
  bool _initializing = false;
  bool _frozen = false;
  bool _torch = false;
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  double _areaFraction = 0.04;

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
        setState(() => _error = l10n.liveNoCamera);
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
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            e.code.contains('AccessDenied') || e.code.contains('Restricted')
            ? l10n.cameraPermissionDenied
            : l10n.cameraError(e.description ?? e.code);
      });
    } finally {
      _initializing = false;
    }
  }

  void _onFrame(CameraImage image) {
    if (_frozen || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastSample) < _minInterval) return;
    _lastSample = now;
    final result = _sampler.sample(_centerPixels(image));
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

  List<int> _centerPixels(CameraImage image) {
    final w = image.width, h = image.height;
    final radius = math.max(2, (math.min(w, h) * _areaFraction).round());
    final cx = w ~/ 2, cy = h ~/ 2;
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
    setState(() => _frozen = !_frozen);
    if (c == null) return;
    try {
      if (_frozen) {
        await c.pausePreview();
      } else {
        await c.resumePreview();
      }
    } on CameraException catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.liveTitle)),
      body: SafeArea(
        // A câmera ocupa sempre a metade de cima; resultado e controles, a
        // de baixo (com rolagem se não couberem).
        child: Column(
          children: [
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    )
                  : controller == null || !controller.value.isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : _CoverPreview(
                      controller: controller,
                      areaFraction: _areaFraction,
                    ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AreaSlider(
                      fraction: _areaFraction,
                      onChanged: (v) => setState(() => _areaFraction = v),
                    ),
                    ValueListenableBuilder<_LiveResult?>(
                      valueListenable: _result,
                      builder: (context, result, _) => result != null
                          ? ResultCard(
                              description: result.description,
                              warnings: result.warnings,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                l10n.liveHint,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleFreeze,
                              icon: Icon(
                                _frozen ? Icons.play_arrow : Icons.pause,
                              ),
                              label: Text(
                                _frozen ? l10n.liveContinue : l10n.liveFreeze,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controller == null
                                  ? null
                                  : _toggleTorch,
                              icon: Icon(
                                _torch
                                    ? Icons.flashlight_off
                                    : Icons.flashlight_on,
                              ),
                              label: Text(
                                _torch ? l10n.liveTorchOff : l10n.liveTorchOn,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _LiveResult {
  const _LiveResult(this.description, this.warnings);

  final ColorDescription description;
  final Set<SampleWarning> warnings;
}

/// Prévia da câmera preenchendo todo o espaço (corta as sobras, sem
/// distorcer), com a mira no centro. O raio da mira acompanha a escala do
/// corte, para mostrar exatamente a área que é lida no quadro.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller, required this.areaFraction});

  final CameraController controller;
  final double areaFraction;

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
        final scale = math.max(w / pw, h / ph);
        final radius = math.max(6.0, math.min(pw, ph) * scale * areaFraction);
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: pw,
                  height: ph,
                  child: CameraPreview(controller),
                ),
              ),
            ),
            _Crosshair(radius: radius),
          ],
        );
      },
    );
  }
}

/// Mira desenhada sobre a prévia. O círculo mostra a área amostrada.
class _Crosshair extends StatelessWidget {
  const _Crosshair({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).crosshairLabel,
      child: CustomPaint(painter: _CrosshairPainter(radius)),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final dark = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final light = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final p in [dark, light]) {
      canvas.drawCircle(c, radius, p);
      final gap = radius + 6, len = radius + 22;
      canvas.drawLine(c.translate(-len, 0), c.translate(-gap, 0), p);
      canvas.drawLine(c.translate(gap, 0), c.translate(len, 0), p);
      canvas.drawLine(c.translate(0, -len), c.translate(0, -gap), p);
      canvas.drawLine(c.translate(0, gap), c.translate(0, len), p);
    }
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.radius != radius;
}
