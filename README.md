# Qual cor?

App Flutter (Android e iOS) que diz **o nome da cor** de um ponto numa foto ou
na câmera ao vivo, para ajudar pessoas daltônicas. Funciona 100% offline: nada
sai do aparelho.

## Como rodar

Requer Flutter 3.50+ (Dart 3.14). Material vem do pacote `material_ui`
(`import 'package:material_ui/material_ui.dart';`), não mais de
`package:flutter/material.dart`.

```bash
flutter pub get        # também gera as traduções (gen-l10n)
flutter test           # testes do motor de cor e da interface
flutter analyze
flutter run            # num iPhone/Android ou no simulador
```

A mira ao vivo precisa de câmera de verdade; no simulador do iOS use
"Escolher da galeria".

## Telas

- **Início:** três botões grandes: *Mira ao vivo*, *Tirar foto* e *Escolher da galeria*.
- **Mira ao vivo:** prévia da câmera na metade de cima da tela, com uma mira
  no centro. A área dentro do círculo é lida até ~20 vezes por segundo. Botões *Congelar /
  Continuar* e *lanterna*.
- **Foto:** a foto aparece inteira; toque (ou arraste) no ponto desejado. Um
  marcador mostra a área lida, e um controle ajusta o tamanho dela.
- **Resultado:** a família da cor em letras bem grandes, uma linha de
  descrição, o nome popular mais próximo, os avisos e, em segundo plano, uma
  amostra pequena e o código hex (escondido por padrão). Com VoiceOver ou
  TalkBack, o resultado inteiro é anunciado automaticamente.

## Decisões de projeto

### Tudo em OKLab

As cores são convertidas de sRGB para **OKLab/OKLCH** (fórmulas de Björn
Ottosson). Médias, distâncias e agrupamentos são feitos nesse espaço, porque
nele a distância euclidiana acompanha bem a diferença que as pessoas percebem.
Em RGB, por exemplo, um azul escuro e um preto ficariam "longe" e dois verdes
claros bem diferentes ficariam "perto".

### Área, nunca um pixel

Um pixel isolado sofre com ruído do sensor, compressão JPEG e textura. Por
isso a cor vem sempre da média de uma **área circular**, de tamanho ajustável
(1 a 10% do lado menor da imagem). Antes da média:

1. **Reflexos especulares** (pixels com L > 0,95 e croma < 0,03) são
   descartados quando são minoria. Se a área inteira for branca, continua
   branca.
2. Um **2-means em OKLab** separa a área em dois grupos. Se o grupo menor tiver
   mais de 25% dos pixels e estiver longe do outro (distância > 0,1), o app
   avisa "a área tem mais de uma cor" e usa o grupo maior.
3. **Avisos:** pouca luz (L < 0,12), superexposição (mais de 25% dos pixels com
   algum canal ≥ 250), reflexo removido e cores misturadas.

Na mira ao vivo (`lib/color/live_smoother.dart`):

- **Mudança grande** (objeto novo, distância OKLab > 0,06): o app pula direto
  para a cor nova e troca o texto no quadro seguinte (~50 ms).
- **Mudança pequena** (ruído do sensor, mão tremendo): média móvel exponencial
  (α = 0,5), e o texto só muda quando o novo resultado se repete em dois
  quadros seguidos, para não piscar na fronteira entre dois nomes.
- A amostragem roda direto na thread da interface: custa menos de 0,1 ms por
  quadro (medido em `test/bench/frame_cost_test.dart`), então um isolate não
  compensaria. Só o painel de resultado é reconstruído a cada amostra; a
  prévia da câmera, não.

A versão anterior (uma amostra a cada 250 ms, α = 0,35, confirmação em 2
amostras) levava de 1,5 a 2 s para mostrar a cor nova. O custo do
processamento em si sempre foi pequeno (< 0,1 ms por quadro no Mac): o atraso
vinha do intervalo e da suavização.

### Nome em três níveis

O daltônico quer, antes de tudo, a **categoria** ("é verde ou marrom?").
Nomes finos como "azul-petróleo" ajudam, mas só quando são confiáveis.

1. **Família:** uma das 11 cores básicas (preto, branco, cinza, vermelho,
   laranja, amarelo, verde, azul, roxo, rosa e marrom). É decidida por
   **k-NN ponderado** (k = 7, peso 1/(d + 0,02)) sobre uma lista curada de
   175 nomes populares brasileiros, cada um marcado com a sua família
   (`lib/color/color_names_pt.dart`). Cores com croma < 0,02 são neutras e
   ficam com preto, cinza ou branco conforme a claridade. Se a segunda família
   somar pelo menos 75% da pontuação da primeira, o app diz **"Entre X e Y"**
   em vez de arriscar.
2. **Descrição:** comparada com a cor canônica da família (vermelho = #FF0000,
   azul = #0000FF...):
   - claridade: *muito claro / claro / escuro / muito escuro*;
   - saturação: *acinzentado / suave / vivo*, pela **saturação relativa**
     (croma ÷ maior croma que o sRGB permite naquela claridade e matiz). Assim
     o azul-marinho, que é escuro mas está no limite da saturação, não sai
     "suave". "Vivo" exige também croma alto;
   - subtom: *"puxando para o {família}"*, pela segunda família cromática do
     k-NN. Cinzas com croma > 0,02 também recebem subtom ("cinza puxando para
     o azul").
3. **Nome popular:** o nome mais próximo da lista aparece como
   **"Parecido com: X"** (distância ≤ 0,035) ou **"Lembra: X"** (≤ 0,075).
   Mais longe que isso, não aparece.

A amostra de cor na tela é pequena e secundária de propósito: quem é daltônico
pode não confiar no que vê nela.

### Textos e idiomas

Todo texto da interface passa pelos arquivos ARB (`lib/l10n/app_pt.arb`,
gen-l10n nativo do Flutter). Famílias, claridade e saturação são mensagens ICU
`select`. Por enquanto só existe português. A lista de nomes populares é um
dicionário de dados, não texto de interface; outro idioma ganharia a sua
própria lista (`color_names_xx.dart`).

### Câmera

- O stream vem em `yuv420` no Android (convertido com BT.601 de faixa cheia) e
  `bgra8888` no iOS. Só os pixels da área central são lidos.
- `enableAudio: false`: o app nunca pede o microfone.
- A cor medida depende da luz e do balanço de branco da câmera. Os avisos
  ajudam, mas luz natural difusa dá os melhores resultados.

### Fotos

A foto é decodificada com `package:image`, recebe a orientação do EXIF
(`bakeOrientation`) e é reduzida para no máximo 1600 px no lado maior, tudo
num isolate separado. A mesma imagem é usada para exibir e para amostrar, então
o toque sempre cai no pixel certo.

## Estrutura

```
lib/
  color/                 motor de cor (Dart puro, com testes)
    oklab.dart           sRGB ↔ OKLab/OKLCH, saturação relativa
    color_names_pt.dart  175 nomes populares e as 11 famílias
    color_namer.dart     os três níveis de nome
    area_sampler.dart    média da área, reflexos, 2-means, avisos
    pixel_area.dart      leitura de pixels (imagem, YUV420, BGRA8888)
  ui/                    telas (material_ui, alto contraste)
  l10n/app_pt.arb        textos
test/                    testes do motor e da interface
```

## Permissões

- iOS: `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` (em
  português) no `Info.plist`.
- Android: `CAMERA`.
