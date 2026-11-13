import 'package:flutter_tts/flutter_tts.dart';

/// Voz em português do Brasil (flutter_tts, offline no aparelho).
class Speech {
  Speech._();
  static final Speech instance = Speech._();

  FlutterTts? _tts;

  Future<FlutterTts> _ready() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    await tts.setLanguage('pt-BR');
    await tts.setSpeechRate(0.5);
    await tts.awaitSpeakCompletion(false);
    _tts = tts;
    return tts;
  }

  Future<void> speak(String text) async {
    try {
      final tts = await _ready();
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      // Sem voz disponível: o texto continua na tela.
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
