// Gera o ícone do app e a imagem da tela de abertura (cartela de tinta),
// sem dependências: desenha retângulos num buffer RGBA e grava PNG com o
// zlib do dart:io. (Sem package:image de propósito: todo pacote do pubspec,
// mesmo de desenvolvimento, aparece na tela de licenças do app.)
//
//   dart run tool/make_icon.dart
//
// Depois, para gerar os tamanhos, siga o passo a passo no fim do pubspec.yaml.
import 'dart:io';
import 'dart:typed_data';

class Canvas {
  Canvas(this.width, this.height) : rgba = Uint8List(width * height * 4);

  final int width, height;
  final Uint8List rgba;

  /// Preenche o retângulo [x0, x1) × [y0, y1) com a cor 0xAARRGGBB,
  /// misturando com o que já está embaixo.
  void rect(int x0, int y0, int x1, int y1, int argb) {
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
    for (var y = y0.clamp(0, height); y < y1.clamp(0, height); y++) {
      for (var x = x0.clamp(0, width); x < x1.clamp(0, width); x++) {
        final i = (y * width + x) * 4;
        if (a == 255) {
          rgba
            ..[i] = r
            ..[i + 1] = g
            ..[i + 2] = b
            ..[i + 3] = 255;
        } else {
          final da = rgba[i + 3];
          final outA = a + da * (255 - a) ~/ 255;
          if (outA == 0) continue;
          int mix(int src, int dst) =>
              (src * a + dst * da * (255 - a) ~/ 255) ~/ outA;
          rgba
            ..[i] = mix(r, rgba[i])
            ..[i + 1] = mix(g, rgba[i + 1])
            ..[i + 2] = mix(b, rgba[i + 2])
            ..[i + 3] = outA;
        }
      }
    }
  }

  List<int> toPng() {
    final raw = BytesBuilder();
    for (var y = 0; y < height; y++) {
      raw.addByte(0); // filtro "nenhum"
      raw.add(Uint8List.sublistView(rgba, y * width * 4, (y + 1) * width * 4));
    }
    final out = BytesBuilder()
      ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    void chunk(String type, List<int> data) {
      final body = [...type.codeUnits, ...data];
      out
        ..add(_u32(data.length))
        ..add(body)
        ..add(_u32(_crc32(body)));
    }

    chunk('IHDR', [..._u32(width), ..._u32(height), 8, 6, 0, 0, 0]);
    chunk('IDAT', ZLibEncoder(level: 9).convert(raw.toBytes()));
    chunk('IEND', const []);
    return out.toBytes();
  }
}

List<int> _u32(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

const ground = 0xFFE9E8E4;
const white = 0xFFFFFFFF;
const teal = 0xFF1F5F5B;
const line1 = 0xFF63625C;
const line2 = 0xFFBDBBB4;

/// Cartela centrada em (cx, cy); `s` = escala (1 = 440x640 px).
void card(Canvas c, int cx, int cy, double s, int shadow) {
  int v(num x) => (x * s).round();
  final w = v(440), h = v(640);
  final x0 = cx - w ~/ 2, y0 = cy - h ~/ 2;
  // Sombra: um retângulo um pouco mais escuro deslocado para baixo.
  c.rect(x0, y0 + v(10), x0 + w, y0 + h + v(10), shadow);
  c.rect(x0, y0, x0 + w, y0 + h, white);
  c.rect(x0, y0, x0 + w, y0 + v(370), teal); // a "tinta"
  // Rótulo, nome e linha de baixo.
  c.rect(x0 + v(40), y0 + v(420), x0 + v(190), y0 + v(436), line2);
  c.rect(x0 + v(40), y0 + v(462), x0 + v(340), y0 + v(506), line1);
  c.rect(x0 + v(40), y0 + v(540), x0 + v(260), y0 + v(558), line2);
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Ícone completo (iOS e Android antigo): fundo + cartela.
  final icon = Canvas(1024, 1024)..rect(0, 0, 1024, 1024, ground);
  card(icon, 512, 512, 1, 0xFFD3D1CB);
  File('assets/icon/icon.png').writeAsBytesSync(icon.toPng());

  // Frente do ícone adaptativo (Android): só a cartela; o gerador ainda
  // aplica 16% de margem e o fundo #E9E8E4 vem da configuração.
  final fg = Canvas(1024, 1024);
  card(fg, 512, 512, 0.95, 0x1C000000);
  File('assets/icon/foreground.png').writeAsBytesSync(fg.toPng());

  // Tela de abertura: cartela sobre transparente, 1152 px com o conteúdo no
  // círculo central, como o Android 12 pede.
  final splash = Canvas(1152, 1152);
  card(splash, 576, 576, 0.7, 0x1C000000);
  File('assets/icon/splash.png').writeAsBytesSync(splash.toPng());
}
