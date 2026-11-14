import '../l10n/generated/app_localizations.dart';
import 'style.dart';

/// Textos que mudam no Modo Warhammer ("Auspex" para a mira, "Estase" para
/// congelar...). Fora do modo devolvem os textos normais.
extension ThemedTexts on AppLocalizations {
  bool get _grim => Palette.grim;

  String get tBarBack => _grim ? whAuspex : barBack;
  String get tBarGallery => _grim ? whGallery : barGallery;
  String get tBarTakePhoto => _grim ? whTakePhoto : barTakePhoto;
  String get tFreeze => _grim ? whFreeze : liveFreeze;
  String get tContinue => _grim ? whContinue : liveContinue;
  String get tFrozenChip => _grim ? whFrozenChip : frozenChip;
  String get tLiveHint => _grim ? whLiveHint : liveHint;
  String get tPhotoTapHint => _grim ? whPhotoTapHint : photoTapHint;
  String get tCrosshairLabel => _grim ? whCrosshairLabel : crosshairLabel;
}
