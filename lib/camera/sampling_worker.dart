import 'dart:async';
import 'dart:isolate';

import '../color/area_sampler.dart';
import '../color/pixel_area.dart';

/// Isolate de vida longa que faz a conversão de cor e a amostragem dos
/// quadros da câmera, fora da thread da interface.
///
/// É criado uma vez com a tela e encerrado no dispose. Recebe só o recorte
/// central do quadro ([FrameCrop], alguns KB); quem chama descarta quadros
/// enquanto um pedido está em andamento ([isBusy]), então nunca forma fila.
/// Não usamos Isolate.run por quadro porque criar um isolate custa mais que
/// a própria amostragem.
class SamplingWorker {
  SamplingWorker._(this._isolate, this._toWorker, this._inbox, this._replies);

  final Isolate _isolate;
  final SendPort _toWorker;
  final ReceivePort _inbox;
  final StreamIterator<dynamic> _replies;
  bool _busy = false;
  bool _disposed = false;

  static Future<SamplingWorker> spawn() async {
    final inbox = ReceivePort();
    final isolate = await Isolate.spawn(
      _main,
      inbox.sendPort,
      debugName: 'amostragem',
    );
    final replies = StreamIterator<dynamic>(inbox);
    await replies.moveNext();
    final toWorker = replies.current as SendPort;
    return SamplingWorker._(isolate, toWorker, inbox, replies);
  }

  bool get isBusy => _busy;

  /// Amostra o recorte no isolate. Um pedido por vez.
  Future<SampleResult?> sample(FrameCrop crop) async {
    if (_busy || _disposed) return null;
    _busy = true;
    try {
      _toWorker.send(crop);
      if (!await _replies.moveNext()) return null;
      return _replies.current as SampleResult?;
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _isolate.kill(priority: Isolate.immediate);
    _inbox.close();
  }

  static void _main(SendPort toMain) {
    final inbox = ReceivePort();
    toMain.send(inbox.sendPort);
    const sampler = AreaSampler();
    inbox.listen((message) {
      final crop = message as FrameCrop;
      toMain.send(sampler.sample(crop.pixels()));
    });
  }
}
