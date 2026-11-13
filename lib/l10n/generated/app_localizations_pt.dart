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
  String get warningLowLight => 'Pouca luz: resultado incerto.';

  @override
  String get warningOverexposed => 'Luz forte demais: a cor pode estar lavada.';

  @override
  String get warningHighlight => 'Ignorei um reflexo.';

  @override
  String get warningMixed => 'Área com mais de uma cor; diminua a área.';

  @override
  String resultSummary(String main, String details) {
    return '$main $details.';
  }

  @override
  String get liveFreeze => 'Congelar';

  @override
  String get liveContinue => 'Continuar';

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
  String get photoError => 'Não foi possível abrir a foto.';

  @override
  String get torch => 'Lanterna';

  @override
  String get labelFamily => 'FAMÍLIA';

  @override
  String get labelArea => 'ÁREA';

  @override
  String areaSizeValue(int percent) {
    return 'Área: $percent% da imagem';
  }

  @override
  String get liveHint => 'Aponte para um objeto';

  @override
  String get photoTapHint => 'Toque no ponto da foto';

  @override
  String get emptyFamily => '—';

  @override
  String get frozenChip => 'CONGELADO';

  @override
  String get liveDragHint => 'Arraste a mira para escolher o ponto.';

  @override
  String get crosshairLabel => 'Mira no centro da imagem';

  @override
  String get markerLabel => 'Ponto escolhido';

  @override
  String get barGallery => 'Galeria';

  @override
  String get barTorch => 'Lanterna';

  @override
  String get barBack => 'Mira';

  @override
  String get barAnotherPhoto => 'Outra foto';

  @override
  String get barTakePhoto => 'Câmera';

  @override
  String get torchOnHint => 'Ligar lanterna';

  @override
  String get torchOffHint => 'Desligar lanterna';

  @override
  String get copyCode => 'Copiar código da cor';

  @override
  String codeCopied(String hex) {
    return 'Código $hex copiado';
  }

  @override
  String colorCode(String hex) {
    return 'Código $hex';
  }

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get photoLoading => 'Abrindo a foto…';

  @override
  String get about => 'Sobre o app';

  @override
  String get aboutDescription =>
      'Diz o nome da cor de um ponto na câmera ou numa foto, para ajudar quem é daltônico. Funciona sem internet.';

  @override
  String aboutVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutLicenses => 'Licenças';

  @override
  String get aboutLicensesSubtitle => 'Bibliotecas e fontes usadas no app';

  @override
  String get labelBetween => 'ENTRE';

  @override
  String familyPair(String first, String second) {
    return '$first e $second';
  }
}
