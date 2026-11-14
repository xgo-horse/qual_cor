import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'color/citadel_namer.dart';

/// Guarda o estado do Modo Warhammer num arquivo JSON pequeno.
///
/// Sem shared_preferences nem path_provider de propósito: todo pacote do
/// pubspec aparece na tela de licenças, e um booleano não justifica meia
/// dúzia deles.
class ModeStore {
  const ModeStore(this.file);

  final File file;

  /// Arquivo dentro da área do app, ou null se a plataforma não tiver um
  /// lugar conhecido (aí o estado vale só enquanto o app está aberto).
  ///
  /// - iOS/macOS: `$HOME` é o contêiner do app; usa Library/Application
  ///   Support (fica no backup e não é limpa pelo sistema).
  /// - Android: o temporário do Dart é a pasta `cache` do app; usa a pasta
  ///   do app, ao lado dela (a cache pode ser limpa).
  static ModeStore? platformDefault() {
    try {
      Directory? dir;
      if (Platform.isIOS || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) dir = Directory('$home/Library/Application Support');
      } else if (Platform.isAndroid) {
        final tmp = Directory.systemTemp;
        if (tmp.path.endsWith('/cache')) dir = tmp.parent;
      }
      if (dir == null) return null;
      return ModeStore(File('${dir.path}/qual_cor_settings.json'));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> read() async {
    try {
      if (!await file.exists()) return {};
      final data = jsonDecode(await file.readAsString());
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // Sem onde gravar: o modo continua valendo até fechar o app.
    }
  }
}

/// Estado do easter egg "Modo Warhammer": ligado ou não, se já foi
/// descoberto (aí aparece um switch na tela Sobre) e as tintas Citadel,
/// carregadas só quando o modo liga.
class WarhammerMode extends ChangeNotifier {
  WarhammerMode({this.store, this.loadNamer = _loadFromAssets});

  ModeStore? store;

  /// Carrega as tintas; trocável nos testes.
  final Future<CitadelNamer> Function() loadNamer;

  bool _enabled = false;
  bool _discovered = false;
  CitadelNamer? _namer;

  /// Ligado e com as tintas prontas.
  bool get enabled => _enabled && _namer != null;
  bool get discovered => _discovered;
  CitadelNamer? get namer => enabled ? _namer : null;

  static Future<CitadelNamer> _loadFromAssets() async =>
      CitadelNamer.fromJson(await rootBundle.loadString(CitadelNamer.asset));

  /// Lê o estado salvo (chamado no main()).
  Future<void> restore() async {
    final s = store;
    if (s == null) return;
    final data = await s.read();
    _discovered = data['discovered'] == true;
    if (data['enabled'] == true) {
      await _ensureNamer();
      _enabled = _namer != null;
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value) await _ensureNamer();
    _enabled = value && _namer != null;
    _discovered = true;
    notifyListeners();
    await store?.write({'enabled': _enabled, 'discovered': _discovered});
  }

  Future<void> toggle() => setEnabled(!enabled);

  Future<void> _ensureNamer() async {
    if (_namer != null) return;
    try {
      _namer = await loadNamer();
    } catch (e) {
      debugPrint('Modo Warhammer: não consegui carregar as tintas: $e');
    }
  }

  /// Só para os testes: volta ao estado inicial, sem gravar nada.
  @visibleForTesting
  void resetForTest() {
    _enabled = false;
    _discovered = false;
    store = null;
    notifyListeners();
  }
}

/// O estado do app inteiro. A paleta e as fontes (lib/ui/style.dart) leem
/// daqui; a interface escuta pelo [WarhammerScope] em app.dart.
final warhammer = WarhammerMode();
