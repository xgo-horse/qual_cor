import 'color_namer.dart';
import 'oklab.dart';

/// Suavização e histerese da mira ao vivo.
///
/// - Mudança grande (objeto novo, distância OKLab > [jumpDistance]): pula
///   direto para a cor nova e troca o texto na hora.
/// - Mudança pequena (ruído do sensor, tremida da mão): média móvel
///   exponencial com [alpha], e o texto só muda quando o novo resultado se
///   repete em dois quadros seguidos, para não piscar na fronteira entre
///   dois nomes.
class LiveSmoother {
  LiveSmoother(this.namer, {this.alpha = 0.5, this.jumpDistance = 0.06});

  final ColorNamer namer;
  final double alpha;
  final double jumpDistance;

  Oklab? _smoothed;
  ColorDescription? _shown;
  String? _pendingKey;

  /// Resultado que deve aparecer na tela.
  ColorDescription? get shown => _shown;

  /// Recebe a cor de um quadro. Devolve true se [shown] mudou.
  bool add(Oklab sample) {
    final prev = _smoothed;
    final jump = prev == null || prev.distanceTo(sample) > jumpDistance;
    final smoothed = jump ? sample : prev.lerp(sample, alpha);
    _smoothed = smoothed;

    final d = namer.describe(smoothed);
    final shown = _shown;
    if (shown == null ||
        jump ||
        d.textKey == shown.textKey ||
        d.textKey == _pendingKey) {
      _pendingKey = null;
      _shown = d;
      return true;
    }
    _pendingKey = d.textKey;
    return false;
  }

  void reset() {
    _smoothed = null;
    _shown = null;
    _pendingKey = null;
  }
}
