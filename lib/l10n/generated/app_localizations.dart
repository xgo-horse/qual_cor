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

  /// Resumo do resultado para o leitor de tela: nome principal e detalhes
  ///
  /// In pt, this message translates to:
  /// **'{main} {details}.'**
  String resultSummary(String main, String details);

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

  /// No description provided for @photoError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a foto.'**
  String get photoError;

  /// Rótulo curto do botão da lanterna (o estado vai na dica e na acessibilidade)
  ///
  /// In pt, this message translates to:
  /// **'Lanterna'**
  String get torch;

  /// Rótulo acima do nome da cor no cartão
  ///
  /// In pt, this message translates to:
  /// **'FAMÍLIA'**
  String get labelFamily;

  /// Rótulo do controle do tamanho da área
  ///
  /// In pt, this message translates to:
  /// **'ÁREA'**
  String get labelArea;

  /// No description provided for @areaSizeValue.
  ///
  /// In pt, this message translates to:
  /// **'Área: {percent}% da imagem'**
  String areaSizeValue(int percent);

  /// Cartão vazio na mira ao vivo
  ///
  /// In pt, this message translates to:
  /// **'Aponte para um objeto'**
  String get liveHint;

  /// Cartão vazio na tela de foto
  ///
  /// In pt, this message translates to:
  /// **'Toque no ponto da foto'**
  String get photoTapHint;

  /// Família enquanto não há resultado
  ///
  /// In pt, this message translates to:
  /// **'—'**
  String get emptyFamily;

  /// Etiqueta sobre a imagem congelada
  ///
  /// In pt, this message translates to:
  /// **'CONGELADO'**
  String get frozenChip;

  /// No description provided for @liveDragHint.
  ///
  /// In pt, this message translates to:
  /// **'Arraste a mira para escolher o ponto.'**
  String get liveDragHint;

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

  /// Botão da barra inferior: abrir foto
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get barGallery;

  /// No description provided for @barTorch.
  ///
  /// In pt, this message translates to:
  /// **'Lanterna'**
  String get barTorch;

  /// Botão da tela de foto que volta para a mira ao vivo
  ///
  /// In pt, this message translates to:
  /// **'Mira'**
  String get barBack;

  /// No description provided for @barAnotherPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Outra foto'**
  String get barAnotherPhoto;

  /// Botão da tela de foto: tirar uma foto nova
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get barTakePhoto;

  /// No description provided for @torchOnHint.
  ///
  /// In pt, this message translates to:
  /// **'Ligar lanterna'**
  String get torchOnHint;

  /// No description provided for @torchOffHint.
  ///
  /// In pt, this message translates to:
  /// **'Desligar lanterna'**
  String get torchOffHint;

  /// Rótulo de acessibilidade do botão de copiar o hex
  ///
  /// In pt, this message translates to:
  /// **'Copiar código da cor'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In pt, this message translates to:
  /// **'Código {hex} copiado'**
  String codeCopied(String hex);

  /// Leitura do hex para o leitor de tela
  ///
  /// In pt, this message translates to:
  /// **'Código {hex}'**
  String colorCode(String hex);

  /// No description provided for @openSettings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir ajustes'**
  String get openSettings;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get retry;

  /// No description provided for @photoLoading.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo a foto…'**
  String get photoLoading;

  /// Botão de informações e título da tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Sobre o app'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In pt, this message translates to:
  /// **'Diz o nome da cor de um ponto na câmera ou numa foto, para ajudar quem é daltônico. Funciona sem internet.'**
  String get aboutDescription;

  /// No description provided for @aboutVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String aboutVersion(String version);

  /// Item da tela Sobre que abre as licenças
  ///
  /// In pt, this message translates to:
  /// **'Licenças'**
  String get aboutLicenses;

  /// No description provided for @aboutLicensesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Bibliotecas e fontes usadas no app'**
  String get aboutLicensesSubtitle;

  /// Rótulo acima do nome quando a cor fica entre duas famílias
  ///
  /// In pt, this message translates to:
  /// **'ENTRE'**
  String get labelBetween;

  /// Nome grande quando a cor fica entre duas famílias (o "Entre" vai no rótulo)
  ///
  /// In pt, this message translates to:
  /// **'{first} e {second}'**
  String familyPair(String first, String second);
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
