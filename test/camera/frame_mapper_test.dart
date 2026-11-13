import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qual_cor/camera/frame_mapper.dart';

void main() {
  // Metade de cima de um iPhone: 390x380, prévia em retrato 480x720 (2:3).
  const view = Size(390, 380);

  FrameMapper android({int rotation = 90, bool mirror = false}) => FrameMapper(
    frameWidth: 720, // quadro deitado, como sai do sensor
    frameHeight: 480,
    rotation: rotation,
    displayAspect: 480 / 720,
    viewSize: view,
    mirror: mirror,
  );

  FrameMapper ios() => FrameMapper(
    frameWidth: 480, // o plugin do iOS já entrega em pé
    frameHeight: 720,
    rotation: 0,
    displayAspect: 480 / 720,
    viewSize: view,
  );

  void close(Offset a, Offset b) {
    expect(a.dx, closeTo(b.dx, 1e-6));
    expect(a.dy, closeTo(b.dy, 1e-6));
  }

  test('centro da tela = centro do quadro (todas as rotações)', () {
    close(ios().viewToFrame(const Offset(195, 190)), const Offset(240, 360));
    for (final r in [90, 270]) {
      close(
        android(rotation: r).viewToFrame(const Offset(195, 190)),
        const Offset(360, 240),
      );
    }
    final r180 = FrameMapper(
      frameWidth: 480,
      frameHeight: 720,
      rotation: 180,
      displayAspect: 480 / 720,
      viewSize: view,
    );
    close(r180.viewToFrame(const Offset(195, 190)), const Offset(240, 360));
  });

  test('corte "cover": prévia 2:3 numa caixa quase quadrada corta em cima e embaixo', () {
    // Largura manda: 390 de largura → 585 de altura mostrada, 102,5 cortados
    // em cima e embaixo.
    final m = ios();
    close(m.viewToFrame(Offset.zero), Offset(0, 102.5 / 585 * 720));
    close(
      m.viewToFrame(const Offset(390, 380)),
      Offset(480, 720 - 102.5 / 585 * 720),
    );
    expect(m.scale, closeTo(390 / 480, 1e-9));
  });

  test('rotação 90 (Android em retrato): canto superior esquerdo da tela é o '
      'inferior esquerdo do sensor', () {
    final m = android();
    // Sem corte lateral: x=0 na tela.
    final topLeftVisible = m.viewToFrame(Offset.zero);
    expect(topLeftVisible.dy, closeTo(480, 1e-6)); // fundo do sensor
    expect(topLeftVisible.dx, closeTo(102.5 / 585 * 720, 1e-6));
    // Direita da tela = topo do sensor.
    expect(m.viewToFrame(const Offset(390, 190)).dy, closeTo(0, 1e-6));
  });

  test('rotação 270: o contrário da 90', () {
    final m = android(rotation: 270);
    expect(m.viewToFrame(const Offset(0, 190)).dy, closeTo(0, 1e-6));
    expect(m.viewToFrame(const Offset(390, 190)).dy, closeTo(480, 1e-6));
  });

  test('ida e volta tela ↔ quadro em todas as rotações e com espelho', () {
    final mappers = [
      ios(),
      android(),
      android(rotation: 270),
      android(mirror: true),
      FrameMapper(
        frameWidth: 640,
        frameHeight: 480,
        rotation: 180,
        displayAspect: 640 / 480,
        viewSize: const Size(300, 500),
      ),
    ];
    for (final m in mappers) {
      for (final p in const [
        Offset(10, 20),
        Offset(195, 190),
        Offset(380, 370),
      ]) {
        close(m.frameToView(m.viewToFrame(p)), p);
      }
    }
  });

  test('espelho (câmera frontal) inverte esquerda e direita', () {
    final a = android().viewToFrame(const Offset(50, 190));
    final b = android(mirror: true).viewToFrame(const Offset(340, 190));
    close(a, b);
  });

  test('limite: o círculo fica dentro do quadro e da parte visível', () {
    final m = ios();
    const r = 20.0;
    final visibleTop = 102.5 / 585 * 720;
    final c = m.clampFrame(const Offset(-50, -50), r);
    close(c, Offset(r, visibleTop + r));
    final d = m.clampFrame(const Offset(9999, 9999), r);
    close(d, Offset(480 - r, 720 - visibleTop - r));
    // Ponto do meio não muda.
    close(m.clampFrame(const Offset(240, 360), r), const Offset(240, 360));
    // Rotacionado (Android): também respeita os limites do sensor.
    final a = android().clampFrame(const Offset(-10, 9999), r);
    expect(a.dx, greaterThanOrEqualTo(r));
    expect(a.dy, lessThanOrEqualTo(480 - r));
  });
}
