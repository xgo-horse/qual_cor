// Lista curada de nomes populares de cores em português do Brasil.
//
// Cada nome tem um valor de referência (hex) e a família básica a que
// pertence. A família decide o nível 1 do resultado (por k-NN ponderado);
// o nome em si só aparece no nível 3 ("Parecido com" / "Lembra").
//
// Os nomes são dados (como um dicionário), não textos de interface: por
// isso ficam aqui e não nos arquivos ARB. Para outro idioma, crie uma
// lista equivalente (por exemplo color_names_en.dart).

import 'oklab.dart';

/// As 11 cores básicas (Berlin & Kay) usadas no nível 1.
enum ColorFamily {
  preto,
  branco,
  cinza,
  vermelho,
  laranja,
  amarelo,
  verde,
  azul,
  roxo,
  rosa,
  marrom;

  bool get isAchromatic =>
      this == preto || this == branco || this == cinza;
}

class NamedColor {
  NamedColor(this.name, this.hex, this.family) : lab = Oklab.fromHex(hex);

  final String name;
  final String hex;
  final ColorFamily family;
  final Oklab lab;
}

const _p = ColorFamily.preto;
const _br = ColorFamily.branco;
const _ci = ColorFamily.cinza;
const _vm = ColorFamily.vermelho;
const _la = ColorFamily.laranja;
const _am = ColorFamily.amarelo;
const _vd = ColorFamily.verde;
const _az = ColorFamily.azul;
const _ro = ColorFamily.roxo;
const _rs = ColorFamily.rosa;
const _ma = ColorFamily.marrom;

final List<NamedColor> colorNamesPt = List.unmodifiable(<NamedColor>[
  // Preto
  NamedColor('preto', '#000000', _p),
  NamedColor('preto fosco', '#1A1A1A', _p),
  NamedColor('ébano', '#15110E', _p),
  NamedColor('preto-azulado', '#0D1117', _p),

  // Branco
  NamedColor('branco', '#FFFFFF', _br),
  NamedColor('branco-gelo', '#F2F3EF', _br),
  NamedColor('off-white', '#F8F6F0', _br),
  NamedColor('branco-neve', '#FFFAFA', _br),
  NamedColor('marfim', '#FFFFF0', _br),
  NamedColor('pérola', '#EEEAE0', _br),

  // Cinza
  NamedColor('cinza', '#808080', _ci),
  NamedColor('cinza-claro', '#C0C0C0', _ci),
  NamedColor('prata', '#BFC1C2', _ci),
  NamedColor('cinza-escuro', '#505050', _ci),
  NamedColor('grafite', '#3F4045', _ci),
  NamedColor('chumbo', '#5B5E62', _ci),
  NamedColor('cinza-chumbo', '#4A4E52', _ci),
  NamedColor('cinza-gelo', '#D9DCDF', _ci),
  NamedColor('cinza-azulado', '#7A8A99', _ci),
  NamedColor('cinza-rato', '#7F7B77', _ci),
  NamedColor('fumê', '#6B6B6B', _ci),
  NamedColor('cimento', '#9B9B93', _ci),
  NamedColor('cinza-pérola', '#C8C6C0', _ci),
  NamedColor('platina', '#E5E4E2', _ci),
  NamedColor('ardósia', '#708090', _ci),
  NamedColor('fendi', '#A89F91', _ci),

  // Vermelho
  NamedColor('vermelho', '#FF0000', _vm),
  NamedColor('vermelho-escuro', '#8B0000', _vm),
  NamedColor('vermelho-sangue', '#8A0303', _vm),
  NamedColor('carmim', '#960018', _vm),
  NamedColor('escarlate', '#FF2400', _vm),
  NamedColor('vermelho-ferrari', '#E10600', _vm),
  NamedColor('vermelho-cereja', '#C2183B', _vm),
  NamedColor('bordô', '#800020', _vm),
  NamedColor('vinho', '#722F37', _vm),
  NamedColor('cor de vinho', '#6D1A2A', _vm),
  NamedColor('grená', '#7B1E2B', _vm),
  NamedColor('marsala', '#964F4C', _vm),
  NamedColor('rubi', '#9B111E', _vm),
  NamedColor('vermelho-tomate', '#FF6347', _vm),
  NamedColor('vermelho-tijolo', '#B22222', _vm),
  NamedColor('framboesa', '#C72C48', _vm),
  NamedColor('vermelho-alaranjado', '#FF4500', _vm),

  // Laranja
  NamedColor('laranja', '#FF8000', _la),
  NamedColor('abóbora', '#FF7518', _la),
  NamedColor('tangerina', '#F28500', _la),
  NamedColor('cenoura', '#ED9121', _la),
  NamedColor('mandarina', '#F37A48', _la),
  NamedColor('laranja-neon', '#FF5F1F', _la),
  NamedColor('laranja-queimado', '#CC5500', _la),
  NamedColor('ferrugem', '#B7410E', _la),
  NamedColor('terracota', '#C8643B', _la),
  NamedColor('coral', '#FF7F50', _la),
  NamedColor('salmão', '#FA8072', _la),
  NamedColor('pêssego', '#FFCBA4', _la),
  NamedColor('damasco', '#FBCEB1', _la),
  NamedColor('laranja-claro', '#FFB347', _la),
  NamedColor('manga', '#FF9F00', _la),
  NamedColor('laranja-amarelado', '#FFA62B', _la),

  // Amarelo
  NamedColor('amarelo', '#FFFF00', _am),
  NamedColor('amarelo-canário', '#FFEF00', _am),
  NamedColor('amarelo-limão', '#FFF700', _am),
  NamedColor('amarelo-ouro', '#FFD700', _am),
  NamedColor('dourado', '#D4AF37', _am),
  NamedColor('mostarda', '#D4A017', _am),
  NamedColor('gema', '#FFC40C', _am),
  NamedColor('açafrão', '#F4C430', _am),
  NamedColor('âmbar', '#FFBF00', _am),
  NamedColor('ocre', '#CC9933', _am),
  NamedColor('amarelo-queimado', '#E1A95F', _am),
  NamedColor('amarelo-pastel', '#FDFD96', _am),
  NamedColor('amarelo-manteiga', '#FFF1A8', _am),
  NamedColor('baunilha', '#F3E5AB', _am),
  NamedColor('creme', '#FFFDD0', _am),
  NamedColor('palha', '#E8D9A0', _am),
  NamedColor('champanhe', '#F7E7CE', _am),
  NamedColor('amarelo-esverdeado', '#D7E02B', _am),

  // Verde
  NamedColor('verde', '#008000', _vd),
  NamedColor('verde-bandeira', '#009C3B', _vd),
  NamedColor('verde-escuro', '#006400', _vd),
  NamedColor('verde-floresta', '#228B22', _vd),
  NamedColor('verde-claro', '#90EE90', _vd),
  NamedColor('verde-limão', '#32CD32', _vd),
  NamedColor('verde-neon', '#39FF14', _vd),
  NamedColor('verde-musgo', '#8A9A5B', _vd),
  NamedColor('verde-oliva', '#808000', _vd),
  NamedColor('verde-militar', '#4B5320', _vd),
  NamedColor('verde-abacate', '#568203', _vd),
  NamedColor('verde-pistache', '#93C572', _vd),
  NamedColor('verde-menta', '#98FF98', _vd),
  NamedColor('menta', '#3EB489', _vd),
  NamedColor('verde-água', '#7FDBC0', _vd),
  NamedColor('verde-esmeralda', '#50C878', _vd),
  NamedColor('verde-jade', '#00A86B', _vd),
  NamedColor('verde-garrafa', '#006A4E', _vd),
  NamedColor('verde-mar', '#2E8B57', _vd),
  NamedColor('verde-petróleo', '#255E59', _vd),
  NamedColor('verde-azulado', '#00827F', _vd),
  NamedColor('verde-sálvia', '#9CAF88', _vd),

  // Azul
  NamedColor('azul', '#0000FF', _az),
  NamedColor('azul-marinho', '#000080', _az),
  NamedColor('azul-escuro', '#00008B', _az),
  NamedColor('azul-noite', '#191970', _az),
  NamedColor('azul-royal', '#4169E1', _az),
  NamedColor('azul-cobalto', '#0047AB', _az),
  NamedColor('azul-safira', '#0F52BA', _az),
  NamedColor('azul-bic', '#1D2FA3', _az),
  NamedColor('azul-anil', '#2E3A87', _az),
  NamedColor('azul-jeans', '#1560BD', _az),
  NamedColor('azul-aço', '#4682B4', _az),
  NamedColor('azul-acinzentado', '#7393B3', _az),
  NamedColor('azul-céu', '#87CEEB', _az),
  NamedColor('azul-celeste', '#9BD3F0', _az),
  NamedColor('azul-bebê', '#89CFF0', _az),
  NamedColor('azul-claro', '#ADD8E6', _az),
  NamedColor('azul-piscina', '#00B5E2', _az),
  NamedColor('azul-petróleo', '#005F6A', _az),
  NamedColor('azul-esverdeado', '#0D98BA', _az),
  NamedColor('azul-tiffany', '#0ABAB5', _az),
  NamedColor('turquesa', '#40E0D0', _az),
  NamedColor('ciano', '#00FFFF', _az),
  NamedColor('azul-elétrico', '#2C75FF', _az),

  // Roxo
  NamedColor('roxo', '#800080', _ro),
  NamedColor('púrpura', '#6A0DAD', _ro),
  NamedColor('violeta', '#8F00FF', _ro),
  NamedColor('índigo', '#4B0082', _ro),
  NamedColor('uva', '#6F2DA8', _ro),
  NamedColor('ametista', '#9966CC', _ro),
  NamedColor('berinjela', '#3B0A45', _ro),
  NamedColor('roxo-escuro', '#301934', _ro),
  NamedColor('ameixa', '#8E4585', _ro),
  NamedColor('orquídea', '#DA70D6', _ro),
  NamedColor('lilás', '#C8A2C8', _ro),
  NamedColor('lilás-claro', '#DCD0FF', _ro),
  NamedColor('lavanda', '#E6E6FA', _ro),
  NamedColor('malva', '#E0B0FF', _ro),
  NamedColor('roxo-azulado', '#5B3FA8', _ro),

  // Rosa
  NamedColor('rosa', '#FFC0CB', _rs),
  NamedColor('rosa-claro', '#FFB6C1', _rs),
  NamedColor('rosa-bebê', '#F4C2C2', _rs),
  NamedColor('rosa-quartzo', '#F7CAC9', _rs),
  NamedColor('rosa-antigo', '#C08081', _rs),
  NamedColor('rosa-chá', '#E8B4A8', _rs),
  NamedColor('rosa-salmão', '#FF91A4', _rs),
  NamedColor('rosa-choque', '#FC0FC0', _rs),
  NamedColor('pink', '#FF69B4', _rs),
  NamedColor('rosa-pink', '#FF1493', _rs),
  NamedColor('magenta', '#FF00FF', _rs),
  NamedColor('fúcsia', '#F400A1', _rs),
  NamedColor('rosa-escuro', '#C71585', _rs),
  NamedColor('goiaba', '#E86A7A', _rs),
  NamedColor('rosé', '#F2C4CE', _rs),

  // Marrom
  NamedColor('marrom', '#964B00', _ma),
  NamedColor('marrom-escuro', '#5C4033', _ma),
  NamedColor('chocolate', '#7B3F00', _ma),
  NamedColor('chocolate amargo', '#3D1C02', _ma),
  NamedColor('café', '#6F4E37', _ma),
  NamedColor('café com leite', '#B5926A', _ma),
  NamedColor('castanho', '#954535', _ma),
  NamedColor('caramelo', '#AF6E2D', _ma),
  NamedColor('canela', '#B5651D', _ma),
  NamedColor('cobre', '#B87333', _ma),
  NamedColor('couro', '#8B5A2B', _ma),
  NamedColor('sépia', '#704214', _ma),
  NamedColor('mogno', '#6A2A1F', _ma),
  NamedColor('conhaque', '#9A463D', _ma),
  NamedColor('tabaco', '#71563E', _ma),
  NamedColor('noz', '#5D432C', _ma),
  NamedColor('avelã', '#A67B5B', _ma),
  NamedColor('camurça', '#A0785A', _ma),
  NamedColor('bege', '#E3CBA5', _ma),
  NamedColor('areia', '#C2B280', _ma),
  NamedColor('cáqui', '#C3B091', _ma),
  NamedColor('nude', '#E3BC9A', _ma),
  NamedColor('terra', '#7B5B3A', _ma),
]);
