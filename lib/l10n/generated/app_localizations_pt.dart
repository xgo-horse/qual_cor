// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Qual cor?';

  @override
  String get homeIntro =>
      'Aponte para algo ou escolha uma foto e toque no ponto que quer saber a cor.';

  @override
  String get homeLive => 'Mira ao vivo';

  @override
  String get homeTakePhoto => 'Tirar foto';

  @override
  String get homeGallery => 'Escolher da galeria';

  @override
  String familyName(String family) {
    String _temp0 = intl.Intl.selectLogic(family, {
      'preto': 'preto',
      'branco': 'branco',
      'cinza': 'cinza',
      'vermelho': 'vermelho',
      'laranja': 'laranja',
      'amarelo': 'amarelo',
      'verde': 'verde',
      'azul': 'azul',
      'roxo': 'roxo',
      'rosa': 'rosa',
      'marrom': 'marrom',
      'other': 'cor',
    });
    return '$_temp0';
  }

  @override
  String familyTitle(String family) {
    String _temp0 = intl.Intl.selectLogic(family, {
      'preto': 'Preto',
      'branco': 'Branco',
      'cinza': 'Cinza',
      'vermelho': 'Vermelho',
      'laranja': 'Laranja',
      'amarelo': 'Amarelo',
      'verde': 'Verde',
      'azul': 'Azul',
      'roxo': 'Roxo',
      'rosa': 'Rosa',
      'marrom': 'Marrom',
      'other': 'Cor',
    });
    return '$_temp0';
  }

  @override
  String betweenFamilies(String first, String second) {
    return 'Entre $first e $second';
  }

  @override
  String lightness(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'muitoClaro': 'muito claro',
      'claro': 'claro',
      'escuro': 'escuro',
      'muitoEscuro': 'muito escuro',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String saturation(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'acinzentado': 'acinzentado',
      'suave': 'suave',
      'vivo': 'vivo',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String undertone(String family) {
    String _temp0 = intl.Intl.selectLogic(family, {
      'preto': 'preto',
      'branco': 'branco',
      'cinza': 'cinza',
      'vermelho': 'vermelho',
      'laranja': 'laranja',
      'amarelo': 'amarelo',
      'verde': 'verde',
      'azul': 'azul',
      'roxo': 'roxo',
      'rosa': 'rosa',
      'marrom': 'marrom',
      'other': 'cor',
    });
    return 'puxando para o $_temp0';
  }

  @override
  String nameParecido(String name) {
    return 'Parecido com: $name';
  }

  @override
  String nameLembra(String name) {
    return 'Lembra: $name';
  }

  @override
  String get warningLowLight =>
      'Pouca luz: o resultado pode não ser confiável.';

  @override
  String get warningOverexposed =>
      'Muita luz ou reflexo forte: a cor pode estar lavada.';

  @override
  String get warningHighlight => 'Ignorei um brilho/reflexo na área.';

  @override
  String get warningMixed =>
      'A área tem mais de uma cor; mostro a predominante. Diminua a área para mais precisão.';

  @override
  String get speak => 'Falar';

  @override
  String get showHex => 'Mostrar código';

  @override
  String get hideHex => 'Esconder código';

  @override
  String hexCode(String hex) {
    return 'Código: $hex';
  }

  @override
  String get swatchLabel => 'Amostra da cor';

  @override
  String spokenResult(String main, String details) {
    return '$main $details.';
  }

  @override
  String get liveTitle => 'Mira ao vivo';

  @override
  String get liveFreeze => 'Congelar';

  @override
  String get liveContinue => 'Continuar';

  @override
  String get liveTorchOn => 'Ligar lanterna';

  @override
  String get liveTorchOff => 'Desligar lanterna';

  @override
  String get liveHint => 'Aponte a mira para o objeto.';

  @override
  String get liveNoCamera => 'Nenhuma câmera disponível.';

  @override
  String cameraError(String error) {
    return 'Não foi possível abrir a câmera: $error';
  }

  @override
  String get cameraPermissionDenied =>
      'Sem permissão para usar a câmera. Libere o acesso nos Ajustes do aparelho.';

  @override
  String get photoTitle => 'Foto';

  @override
  String get photoTapHint => 'Toque no ponto da foto que quer saber a cor.';

  @override
  String get photoLoading => 'Abrindo a foto…';

  @override
  String get photoError => 'Não foi possível abrir a foto.';

  @override
  String get photoChooseAnother => 'Outra foto';

  @override
  String get areaSize => 'Tamanho da área';

  @override
  String areaSizeValue(int percent) {
    return '$percent% da imagem';
  }

  @override
  String get crosshairLabel => 'Mira no centro da imagem';

  @override
  String get markerLabel => 'Ponto escolhido';
}
