// Gera o ícone do app e a imagem da tela de abertura (cartela de tinta).
//   dart run tool/make_icon.dart
// Depois: dart run flutter_launcher_icons && dart run flutter_native_splash:create
import 'dart:io';

import 'package:image/image.dart' as img;

final ground = img.ColorRgba8(0xE9, 0xE8, 0xE4, 255);
final white = img.ColorRgba8(255, 255, 255, 255);
final teal = img.ColorRgba8(0x1F, 0x5F, 0x5B, 255);
final line1 = img.ColorRgba8(0x63, 0x62, 0x5C, 255);
final line2 = img.ColorRgba8(0xBD, 0xBB, 0xB4, 255);

/// Cartela centrada em (cx, cy); `s` = escala (1 = 440x640 px).
void card(img.Image im, int cx, int cy, double s, img.Color shadow) {
  int v(num x) => (x * s).round();
  final w = v(440), h = v(640);
  final x0 = cx - w ~/ 2, y0 = cy - h ~/ 2;
  // Sombra: um retângulo um pouco mais escuro deslocado para baixo.
  img.fillRect(
    im,
    x1: x0,
    y1: y0 + v(10),
    x2: x0 + w,
    y2: y0 + h + v(10),
    color: shadow,
  );
  img.fillRect(im, x1: x0, y1: y0, x2: x0 + w, y2: y0 + h, color: white);
  // A "tinta".
  img.fillRect(im, x1: x0, y1: y0, x2: x0 + w, y2: y0 + v(370), color: teal);
  // Rótulo e nome (duas linhas).
  img.fillRect(
    im,
    x1: x0 + v(40),
    y1: y0 + v(420),
    x2: x0 + v(40) + v(150),
    y2: y0 + v(420) + v(16),
    color: line2,
  );
  img.fillRect(
    im,
    x1: x0 + v(40),
    y1: y0 + v(462),
    x2: x0 + v(40) + v(300),
    y2: y0 + v(462) + v(44),
    color: line1,
  );
  img.fillRect(
    im,
    x1: x0 + v(40),
    y1: y0 + v(540),
    x2: x0 + v(40) + v(220),
    y2: y0 + v(540) + v(18),
    color: line2,
  );
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Ícone completo (iOS e Android antigo): fundo + cartela.
  final icon = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(icon, color: ground);
  card(icon, 512, 512, 1, img.ColorRgba8(0xD3, 0xD1, 0xCB, 255));
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));

  // Frente do ícone adaptativo (Android): só a cartela, dentro da área
  // segura (o gerador ainda aplica 16% de margem); o fundo #E9E8E4 vem da
  // configuração.
  final fg = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  card(fg, 512, 512, 0.95, img.ColorRgba8(0, 0, 0, 28));
  File('assets/icon/foreground.png').writeAsBytesSync(img.encodePng(fg));

  // Tela de abertura: cartela pequena sobre transparente (o fundo é a cor
  // da tela de abertura). 1152 px com o conteúdo no círculo central, como o
  // Android 12 pede.
  final splash = img.Image(width: 1152, height: 1152, numChannels: 4);
  img.fill(splash, color: img.ColorRgba8(0, 0, 0, 0));
  card(splash, 576, 576, 0.7, img.ColorRgba8(0, 0, 0, 28));
  File('assets/icon/splash.png').writeAsBytesSync(img.encodePng(splash));
}
