import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qual_cor/ui/photo_page.dart';

void main() {
  test('foto em pé na metade de cima (caixa larga): faixas nas laterais', () {
    // Foto 1200x1600 numa caixa 400x300 (metade de cima da tela).
    final l = ContainLayout(const Size(1200, 1600), const Size(400, 300));
    expect(l.dest, const Rect.fromLTWH(87.5, 0, 225, 300));
    expect(l.scale, closeTo(0.1875, 1e-9));
    // Centro da caixa → centro da foto.
    expect(l.toImage(const Offset(200, 150)), const Offset(600, 800));
    // Canto superior esquerdo da foto.
    expect(l.toImage(const Offset(87.5, 0)), Offset.zero);
    // Toque na faixa preta: ignorado.
    expect(l.toImage(const Offset(20, 150)), isNull);
  });

  test('foto deitada numa caixa alta: faixas em cima e embaixo', () {
    final l = ContainLayout(const Size(1600, 900), const Size(320, 400));
    expect(l.dest.width, 320);
    expect(l.dest.height, closeTo(180, 1e-9));
    expect(l.toImage(const Offset(160, 200)), const Offset(800, 450));
    expect(l.toImage(const Offset(160, 50)), isNull);
  });

  test('ida e volta tela ↔ imagem', () {
    final l = ContainLayout(const Size(1000, 750), const Size(390, 360));
    const p = Offset(321, 456);
    final back = l.toImage(l.toLocal(p))!;
    expect(back.dx, closeTo(p.dx, 1e-6));
    expect(back.dy, closeTo(p.dy, 1e-6));
  });

  test('borda direita não passa do último pixel', () {
    final l = ContainLayout(const Size(100, 100), const Size(200, 200));
    final p = l.toImage(const Offset(199.999, 199.999))!;
    expect(p.dx, lessThanOrEqualTo(99));
    expect(p.dy, lessThanOrEqualTo(99));
  });
}
