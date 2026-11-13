import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// Nome do app
  ///
  /// In pt, this message translates to:
  /// **'Qual cor?'**
  String get appTitle;

  /// No description provided for @homeIntro.
  ///
  /// In pt, this message translates to:
  /// **'Aponte para algo ou escolha uma foto e toque no ponto que quer saber a cor.'**
  String get homeIntro;

  /// Botão: abre a câmera com mira no centro
  ///
  /// In pt, this message translates to:
  /// **'Mira ao vivo'**
  String get homeLive;

  /// No description provided for @homeTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get homeTakePhoto;

  /// No description provided for @homeGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get homeGallery;

  /// Nome da família de cor (minúsculo, para frases)
  ///
  /// In pt, this message translates to:
  /// **'{family, select, preto{preto} branco{branco} cinza{cinza} vermelho{vermelho} laranja{laranja} amarelo{amarelo} verde{verde} azul{azul} roxo{roxo} rosa{rosa} marrom{marrom} other{cor}}'**
  String familyName(String family);

  /// Nome da família de cor com maiúscula, para o título grande
  ///
  /// In pt, this message translates to:
  /// **'{family, select, preto{Preto} branco{Branco} cinza{Cinza} vermelho{Vermelho} laranja{Laranja} amarelo{Amarelo} verde{Verde} azul{Azul} roxo{Roxo} rosa{Rosa} marrom{Marrom} other{Cor}}'**
  String familyTitle(String family);

  /// Cor que fica entre duas famílias
  ///
  /// In pt, this message translates to:
  /// **'Entre {first} e {second}'**
  String betweenFamilies(String first, String second);

  /// No description provided for @lightness.
  ///
  /// In pt, this message translates to:
  /// **'{value, select, muitoClaro{muito claro} claro{claro} escuro{escuro} muitoEscuro{muito escuro} other{}}'**
  String lightness(String value);

  /// No description provided for @saturation.
  ///
  /// In pt, this message translates to:
  /// **'{value, select, acinzentado{acinzentado} suave{suave} vivo{vivo} other{}}'**
  String saturation(String value);

  /// Subtom: segunda família mais próxima
  ///
  /// In pt, this message translates to:
  /// **'puxando para o {family, select, preto{preto} branco{branco} cinza{cinza} vermelho{vermelho} laranja{laranja} amarelo{amarelo} verde{verde} azul{azul} roxo{roxo} rosa{rosa} marrom{marrom} other{cor}}'**
  String undertone(String family);

  /// No description provided for @nameParecido.
  ///
  /// In pt, this message translates to:
  /// **'Parecido com: {name}'**
  String nameParecido(String name);

  /// No description provided for @nameLembra.
  ///
  /// In pt, this message translates to:
  /// **'Lembra: {name}'**
  String nameLembra(String name);

  /// No description provided for @warningLowLight.
  ///
  /// In pt, this message translates to:
  /// **'Pouca luz: resultado incerto.'**
  String get warningLowLight;

  /// No description provided for @warningOverexposed.
  ///
  /// In pt, this message translates to:
  /// **'Luz forte demais: a cor pode estar lavada.'**
  String get warningOverexposed;

  /// No description provided for @warningHighlight.
  ///
  /// In pt, this message translates to:
  /// **'Ignorei um reflexo.'**
  String get warningHighlight;

  /// No description provided for @warningMixed.
  ///
  /// In pt, this message translates to:
  /// **'Área com mais de uma cor; diminua a área.'**
  String get warningMixed;

  /// No description provided for @showHex.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar código'**
  String get showHex;

  /// No description provided for @hideHex.
  ///
  /// In pt, this message translates to:
  /// **'Esconder código'**
  String get hideHex;

  /// No description provided for @hexCode.
  ///
  /// In pt, this message translates to:
  /// **'Código: {hex}'**
  String hexCode(String hex);

  /// Rótulo de acessibilidade do quadradinho de cor
  ///
  /// In pt, this message translates to:
  /// **'Amostra da cor'**
  String get swatchLabel;

  /// Resumo do resultado para o leitor de tela: nome principal e detalhes
  ///
  /// In pt, this message translates to:
  /// **'{main} {details}.'**
  String resultSummary(String main, String details);

  /// No description provided for @liveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mira ao vivo'**
  String get liveTitle;

  /// No description provided for @liveFreeze.
  ///
  /// In pt, this message translates to:
  /// **'Congelar'**
  String get liveFreeze;

  /// No description provided for @liveContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get liveContinue;

  /// No description provided for @liveTorchOn.
  ///
  /// In pt, this message translates to:
  /// **'Ligar lanterna'**
  String get liveTorchOn;

  /// No description provided for @liveTorchOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligar lanterna'**
  String get liveTorchOff;

  /// No description provided for @liveHint.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a mira para o objeto.'**
  String get liveHint;

  /// No description provided for @liveNoCamera.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma câmera disponível.'**
  String get liveNoCamera;

  /// No description provided for @cameraError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a câmera: {error}'**
  String cameraError(String error);

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão para usar a câmera. Libere o acesso nos Ajustes do aparelho.'**
  String get cameraPermissionDenied;

  /// No description provided for @photoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Foto'**
  String get photoTitle;

  /// No description provided for @photoTapHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque no ponto da foto que quer saber a cor.'**
  String get photoTapHint;

  /// No description provided for @photoLoading.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo a foto…'**
  String get photoLoading;

  /// No description provided for @photoError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a foto.'**
  String get photoError;

  /// No description provided for @photoChooseAnother.
  ///
  /// In pt, this message translates to:
  /// **'Outra foto'**
  String get photoChooseAnother;

  /// Rótulo do controle deslizante do tamanho da área amostrada
  ///
  /// In pt, this message translates to:
  /// **'Tamanho da área'**
  String get areaSize;

  /// No description provided for @areaSizeValue.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% da imagem'**
  String areaSizeValue(int percent);

  /// No description provided for @crosshairLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mira no centro da imagem'**
  String get crosshairLabel;

  /// No description provided for @markerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ponto escolhido'**
  String get markerLabel;

  /// Rótulo curto do botão da lanterna (o estado vai na dica e na acessibilidade)
  ///
  /// In pt, this message translates to:
  /// **'Lanterna'**
  String get torch;

  /// Rótulo curto do botão que mostra/esconde o código hex
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get hexToggle;

  /// Aviso sobre a imagem congelada: a mira pode ser movida
  ///
  /// In pt, this message translates to:
  /// **'Arraste a mira para escolher o ponto'**
  String get liveDragHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
