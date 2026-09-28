# Design system (estilo krython.com) + responsividade — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao VaiViver uma identidade visual inspirada em krython.com (Satoshi,
azul-ciano/índigo, vidro fosco, brilho, gradiente, toques de terminal) com temas
claro e escuro, e corrigir os textos que passam da tela.

**Architecture:** Tokens em três camadas: `AppPalette` (valores crus) →
`ColorScheme` + `VaiViverTokens` (ThemeExtension) → temas de componente em
`AppTheme`. Os widgets do Material herdam o visual sozinhos. Um conjunto pequeno
de widgets próprios cobre o que o Material não expressa (vidro, fundo ambiente,
rótulo terminal). A responsividade é garantida pela estrutura: toda tela é
`AppScreen` + `ResponsiveBody` (área segura + scroll + largura máxima + ação fixa
no rodapé), e uma matriz de testes de layout roda cada tela em vários tamanhos
de celular e de fonte.

**Tech Stack:** Flutter 3.47.5 (via FVM), Material 3, Riverpod 3, flutter_test.
Fontes Satoshi (Fontshare, licença ITF FFL) e JetBrains Mono (OFL).

**Spec:** não há spec separada. As decisões foram acordadas na conversa de
2026-09-27 e estão na seção "Decisões de design" abaixo. A Tarefa 9 as registra
em `docs/design.md` §10 e em `docs/requirements.md` (RNF09, RNF10).

## Decisões de design

- **O que vem do Krython:** tipografia e paleta; vidro, brilho e gradiente; toque
  terminal/dev. **Fica de fora:** movimento, ou seja, nenhuma animação decorativa
  (fade-in, card que sobe ao tocar, pulso). As transições padrão do Material
  continuam.
- **Temas:** claro e escuro, seguindo o sistema (`ThemeMode.system`).
- **Escopo:** design system mais repaginação das telas existentes (onboarding,
  Home, Permissões, Configurações). As telas e os fluxos continuam os mesmos.
- **Abordagem:** tema Material 3, tokens extras em `ThemeExtension` e poucos
  componentes próprios. Não é uma biblioteca de widgets do zero.
- **Cores:** vêm do CSS do krython.com (`/styles/theme.css`). O ciano do site
  (`#2B95D3`) tem contraste de só 3,3:1 com branco, então vira `brandGradient` e
  brilho decorativo. O `primary` usado em texto e botões é um ciano mais escuro
  (`#1B78B0`, 4,8:1).

## Causa do bug de responsividade (investigada, não suposta)

Reproduzido com um teste descartável que renderiza cada tela em 393×873 e
360×640 dp, com fonte de 1,0× a 2,0× e barras do sistema simuladas (36dp em
cima, 24dp embaixo):

1. **Sem área segura no onboarding (causa principal, acontece em qualquer
   tamanho).** O Flutter 3.47 com o `targetSdk` atual desenha o app
   edge-to-edge, por trás das barras do sistema. Os passos do onboarding não
   têm `AppBar` nem `SafeArea`. Por isso, o título de cada permissão começa em
   y=32dp, embaixo da barra de status.
2. **Layout que não rola.** `WelcomeStep` é um `Column` centralizado sem scroll
   (estoura 39px em 360×640 com fonte 1,5×). No `_StepScaffold`, o conteúdo é
   `Expanded(child: ListTile)`. Quando a explicação não cabe, o `ListTile` passa
   da borda de baixo **sem reportar erro nenhum**: com fonte 2,0×, o texto da
   bateria termina em y=1481 numa tela de 873dp. O formulário do passo 4 estoura
   272px em 360×640 com fonte 2,0×.
3. **`ListTile` usado para texto explicativo longo.** Ele foi feito para 1 a 3
   linhas, e o botão "Abrir" disputa a largura com o texto.
4. **Secundário:** Home e Configurações usam `ListView(padding: EdgeInsets.all(16))`.
   Com padding explícito, o `ListView` deixa de somar a altura da barra de
   navegação, então o final da lista nunca sobe totalmente acima dela.

A correção é estrutural (Tarefa 4): um único widget de corpo, `ResponsiveBody`,
usado por todas as telas, com teste de layout em cada tela.

## Padrões usados (e por quê)

- **Tokens em camadas (primitivo → semântico → componente).** Só `AppPalette`
  conhece valores hex. `AppTheme` decide onde cada cor vai. As telas só pedem
  "a cor de sucesso" ou "o vidro". Trocar a paleta inteira é mexer em um arquivo,
  e o teste de contraste roda sobre esse arquivo.
- **`ThemeExtension` com `lerp`.** É o mecanismo oficial para pôr tokens próprios
  no `ThemeData`. Quando o sistema troca claro↔escuro, o `MaterialApp` interpola
  o `ThemeData` inteiro e chama `VaiViverTokens.lerp`, então vidro, brilho e
  gradiente fazem a transição junto com as cores do Material, sem código extra.
- **Estilo no tema, não na chamada.** O gradiente do botão principal fica em
  `elevatedButtonTheme.backgroundBuilder`. Todo `ElevatedButton` do app ganha o
  visual sem mudar nenhuma chamada. Os testes que procuram
  `find.widgetWithText(ElevatedButton, 'Próximo')` continuam funcionando.
- **Layout seguro por construção.** Em vez de lembrar de `SafeArea` e scroll em
  cada tela, a tela só consegue ser montada do jeito certo (`AppScreen` +
  `ResponsiveBody`), e a matriz `phoneViewports` pega regressões.
- **Semântica como contrato de teste.** `StatValue` e o cabeçalho do
  `PermissionCard` expõem um rótulo único ("Reels bloqueados hoje: 4",
  "Acessibilidade: ativada") via `Semantics`. O leitor de tela lê uma frase, e o
  teste procura por ela com `find.bySemanticsLabel`. O mesmo rótulo serve à
  acessibilidade e ao teste.

## Global Constraints

- Flutter e Dart via FVM: `.fvm/flutter_sdk/bin/flutter` e
  `.fvm/flutter_sdk/bin/dart` (Flutter 3.47.5). O `flutter` do PATH não existe
  nesta máquina.
- **Nunca rodar `git commit`** (CLAUDE.md). Cada tarefa termina com as mudanças
  no working tree, e a Soraya revisa e commita.
- A partir da Tarefa 2, rode `tool/fetch_fonts.sh` uma vez antes de
  `flutter test`/`build` num clone novo.
- As fontes **não** entram no git: `/assets/fonts/` fica no `.gitignore`. A
  licença FFL da Satoshi proíbe disponibilizar os arquivos, e o repositório
  `github.com/SorayaFerreira/vai-viver` é público.
- Texto de UI em pt-BR (RNF08). Comentários de código em inglês (padrão do repo).
- Sem animações decorativas. Só transições padrão do Material.
- As keys existentes continuam iguais: `reels-block-switch`,
  `scroll-limit-switch`, `scroll-limit-decrement`, `scroll-limit-increment` e
  `autostart-ack-checkbox`.
- Contraste WCAG AA: texto ≥ 4,5:1 e componentes não-texto ≥ 3:1. Se um par
  falhar no teste, ajuste a cor, nunca o limite.
- Toda tela usa `AppScreen` + `ResponsiveBody`. Nenhum conteúdo em `Column` de
  altura fixa sem scroll.
- Todo teste de widget que renderiza UI do app usa `themedApp(...)`
  (`test/helpers/themed_app.dart`, Tarefa 2). Os widgets do design system
  exigem `VaiViverTokens` no tema.
- Fim de cada tarefa: `.fvm/flutter_sdk/bin/dart format lib test`,
  `.fvm/flutter_sdk/bin/flutter analyze` sem issues e
  `.fvm/flutter_sdk/bin/flutter test` todo verde.

## Review Focus

1. **Fonte do sistema grande** (o MIUI vai até cerca de 2,0×) em tela compacta:
   todo texto continua legível rolando a tela, nada é cortado. Coberto pela
   matriz `phoneViewports`, aplicada a cada tela nas Tarefas 5 a 8.
2. **Navegação por 3 botões** (barra inferior de 48dp): o botão fixo
   "Próximo"/"Concluir" fica acima da barra. Coberto pelo viewport
   `compact-3-button-nav` da matriz (Tarefas 4 e 8).
3. **Troca claro/escuro com o app aberto:** o app acompanha e os tokens
   próprios fazem a transição junto. Coberto pelo teste de `ThemeMode.system` em
   `main_test.dart` e pelo teste de `VaiViverTokens.lerp` (Tarefa 2).
4. **Paisagem e tela dividida** (altura de cerca de 393dp): o conteúdo rola e a
   ação fixa continua visível. Coberto pelo viewport `landscape` (Tarefas 4 a 8).
5. **Leitor de tela (TalkBack):** o prompt decorativo `~/vaiviver $` não é lido,
   e estatísticas e status de permissão são lidos como uma frase. Coberto pelos
   testes de `TerminalLabel` e `StatValue` (Tarefa 3) e pelo teste de semântica
   do `PermissionCard` (Tarefa 5).

## Mapa de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `tool/fetch_fonts.sh` (novo) | Baixa Satoshi e JetBrains Mono para `assets/fonts/` |
| `lib/core/theme/app_palette.dart` (novo) | Todas as cores cruas, clara e escura |
| `lib/core/theme/app_dimens.dart` (novo) | Escala de espaçamento e raios |
| `lib/core/theme/app_typography.dart` (novo) | Famílias, estilo mono, pesos do `TextTheme` |
| `lib/core/theme/vaiviver_tokens.dart` (novo) | `ThemeExtension` + `context.tokens` |
| `lib/core/theme/app_theme.dart` (novo) | Monta `ThemeData` claro/escuro a partir da paleta |
| `lib/core/ui/ambient_background.dart` (novo) | Fundo com grade "matrix" e brilhos |
| `lib/core/ui/glass_card.dart` (novo) | Superfície de vidro fosco, opcionalmente tocável |
| `lib/core/ui/terminal_label.dart` (novo) | Rótulo `~/vaiviver $ comando` em mono |
| `lib/core/ui/status_pill.dart` (novo) | Pílula de status (sucesso/aviso) |
| `lib/core/ui/gradient_text.dart` (novo) | Texto preenchido com o gradiente da marca |
| `lib/core/ui/stat_value.dart` (novo) | Número grande + rótulo, lido como uma frase |
| `lib/core/ui/app_screen.dart` (novo) | Moldura da tela: fundo, Scaffold transparente, AppBar |
| `lib/core/ui/responsive_body.dart` (novo) | Corpo seguro: SafeArea, scroll, largura máx., ação fixa |
| `lib/features/permissions/permission_card.dart` (novo) | Card de permissão com explicação livre e ação abaixo |
| `lib/main.dart` | Liga tema claro/escuro; tela de carregamento usa `AppScreen` |
| `lib/features/**` (telas e tiles) | Repaginação sobre os componentes acima |
| `test/helpers/themed_app.dart` (novo) | `MaterialApp` com o tema real, para testes |
| `test/helpers/phone_viewport.dart` (novo) | Matriz de celulares e asserção "cabe na tela" |
| `pubspec.yaml`, `.gitignore`, `CLAUDE.md`, `docs/*` | Fontes, setup e documentação |

---

### Task 1: Paleta de cores com teste de contraste

**Files:**
- Create: `lib/core/theme/app_palette.dart`
- Test: `test/core/theme/app_palette_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `AppPalette` com `static const AppPalette light` e `dark`. Campos
  (todos `Color`, exceto `brightness`): `brightness` (`Brightness`),
  `background`, `surface`, `surfaceContainerHighest`, `onSurface`,
  `onSurfaceVariant`, `outline`, `outlineVariant`, `primary`, `onPrimary`,
  `primaryContainer`, `onPrimaryContainer`, `secondary`, `onSecondary`,
  `tertiary`, `onTertiary`, `gradientStart`, `gradientEnd`, `error`, `onError`,
  `success`, `successContainer`, `warning`, `warningContainer`, `glassFill`,
  `glassBorder`, `glowPrimary`, `glowSecondary`, `gridLine`.

- [ ] **Step 1: Escrever o teste que falha**

`test/core/theme/app_palette_test.dart`:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/theme/app_palette.dart';

/// WCAG 2.x contrast ratio between two opaque colors (1.0 to 21.0).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('contrastRatio: black on white is 21:1', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
  });

  for (final (name, p) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('$name palette meets WCAG AA', () {
      // Text and icons: at least 4.5:1.
      final textPairs = <String, (Color, Color)>{
        'onSurface on background': (p.onSurface, p.background),
        'onSurface on surface': (p.onSurface, p.surface),
        'onSurfaceVariant on background': (p.onSurfaceVariant, p.background),
        'onSurfaceVariant on surface': (p.onSurfaceVariant, p.surface),
        'primary on background': (p.primary, p.background),
        'primary on surface': (p.primary, p.surface),
        'onPrimary on primary': (p.onPrimary, p.primary),
        'onPrimary on gradientStart': (p.onPrimary, p.gradientStart),
        'onPrimary on gradientEnd': (p.onPrimary, p.gradientEnd),
        'onPrimaryContainer on primaryContainer': (
          p.onPrimaryContainer,
          p.primaryContainer,
        ),
        'success on successContainer': (p.success, p.successContainer),
        'warning on warningContainer': (p.warning, p.warningContainer),
        'error on surface': (p.error, p.surface),
        'onError on error': (p.onError, p.error),
      };
      for (final MapEntry(key: pair, value: (fg, bg)) in textPairs.entries) {
        test('text: $pair >= 4.5', () {
          expect(fg.a, 1.0, reason: 'contrast needs opaque colors');
          expect(bg.a, 1.0, reason: 'contrast needs opaque colors');
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      // Non-text UI (switch/checkbox borders): at least 3:1.
      final uiPairs = <String, (Color, Color)>{
        'outline on background': (p.outline, p.background),
        'outline on surface': (p.outline, p.surface),
      };
      for (final MapEntry(key: pair, value: (fg, bg)) in uiPairs.entries) {
        test('ui: $pair >= 3.0', () {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(3.0));
        });
      }
    });
  }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/theme/app_palette_test.dart`
Expected: FAIL com erro de compilação (`app_palette.dart` não existe).

- [ ] **Step 3: Implementar a paleta**

`lib/core/theme/app_palette.dart`:

```dart
import 'package:flutter/material.dart';

/// Raw color values of the VaiViver design system, one instance per
/// brightness. Inspired by krython.com: cyan-blue primary, indigo/violet
/// accents, near-white (light) or near-black bluish (dark) backgrounds.
///
/// This is the only file that holds hex values. Widgets never read it
/// directly: AppTheme maps it into ColorScheme + VaiViverTokens.
@immutable
class AppPalette {
  const AppPalette._({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.onTertiary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.error,
    required this.onError,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.glassFill,
    required this.glassBorder,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.gridLine,
  });

  final Brightness brightness;

  // Surfaces and text.
  final Color background;
  final Color surface;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;

  // Brand.
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color onTertiary;
  final Color gradientStart;
  final Color gradientEnd;

  // Status.
  final Color error;
  final Color onError;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;

  // Ambient effects (translucent on purpose).
  final Color glassFill;
  final Color glassBorder;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color gridLine;

  static const light = AppPalette._(
    brightness: Brightness.light,
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFE5E7EB),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF4B5563),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFFE4E4E7),
    // krython's #2B95D3 only reaches 3.3:1 on white; this darker cyan
    // passes AA for text. The site's cyan survives in the glows.
    primary: Color(0xFF1B78B0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF3730A3),
    secondary: Color(0xFF4F46E5),
    onSecondary: Color(0xFFFFFFFF),
    tertiary: Color(0xFF7C3AED),
    onTertiary: Color(0xFFFFFFFF),
    gradientStart: Color(0xFF1B78B0),
    gradientEnd: Color(0xFF4F46E5),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF047857),
    successContainer: Color(0xFFD1FAE5),
    warning: Color(0xFF92400E),
    warningContainer: Color(0xFFFEF3C7),
    glassFill: Color(0xB8FFFFFF),
    glassBorder: Color(0x1A111827),
    glowPrimary: Color(0x2E00B4FF),
    glowSecondary: Color(0x248B5CF6),
    gridLine: Color(0x0F00B4DC),
  );

  static const dark = AppPalette._(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A10),
    surface: Color(0xFF0F0F17),
    surfaceContainerHighest: Color(0xFF27272F),
    onSurface: Color(0xFFFAFAFA),
    onSurfaceVariant: Color(0xFFBCBCC2),
    outline: Color(0xFF8B8B94),
    outlineVariant: Color(0xFF313135),
    primary: Color(0xFF51D0FA),
    onPrimary: Color(0xFF0A0A10),
    primaryContainer: Color(0xFF1E1B4B),
    onPrimaryContainer: Color(0xFFC7D2FE),
    secondary: Color(0xFF818CF8),
    onSecondary: Color(0xFF0A0A10),
    tertiary: Color(0xFFC084FC),
    onTertiary: Color(0xFF0A0A10),
    gradientStart: Color(0xFF22D3EE),
    gradientEnd: Color(0xFF818CF8),
    error: Color(0xFFF87171),
    onError: Color(0xFF0A0A10),
    success: Color(0xFF34D399),
    successContainer: Color(0xFF064E3B),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF451A03),
    glassFill: Color(0x80111827),
    glassBorder: Color(0x1FFFFFFF),
    glowPrimary: Color(0x2600D2FF),
    glowSecondary: Color(0x26C084FC),
    gridLine: Color(0x0A20E0FF),
  );
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/theme/app_palette_test.dart`
Expected: PASS (todos os pares). Se algum par falhar, ajuste a cor e não o
limite: escureça-a no tema claro ou clareie-a no escuro, em passos de uns 5% de
luminosidade, até passar.

- [ ] **Step 5: Formatar, analisar e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze`
Expected: `No issues found!`. **Não commitar**: deixe no working tree.

---

### Task 2: Fontes, tokens, `AppTheme` e tema claro/escuro no app

**Files:**
- Create: `tool/fetch_fonts.sh`, `lib/core/theme/app_dimens.dart`,
  `lib/core/theme/app_typography.dart`, `lib/core/theme/vaiviver_tokens.dart`,
  `lib/core/theme/app_theme.dart`, `test/helpers/themed_app.dart`,
  `test/core/theme/app_theme_test.dart`
- Modify: `pubspec.yaml` (seção `flutter:`), `.gitignore`, `lib/main.dart`
  (`VaiViverApp.build`), `test/main_test.dart`, e os wrappers de
  `test/features/home/home_screen_test.dart`,
  `test/features/onboarding/onboarding_flow_screen_test.dart`,
  `test/features/permissions/permissions_screen_test.dart` e
  `test/features/settings/settings_screen_test.dart`

**Interfaces:**
- Consumes: `AppPalette` (Task 1).
- Produces:
  - `AppSpacing.xs/sm/md/lg/xl/xxl` = 4/8/12/16/24/32 (`double`); `AppRadius.card` = 16.
  - `AppTypography.sans` = `'Satoshi'`, `AppTypography.monoFamily` =
    `'JetBrainsMono'`, `AppTypography.mono` (`TextStyle`, 12sp),
    `AppTypography.refine(TextTheme) → TextTheme`.
  - `VaiViverTokens` (ThemeExtension): `success`, `successContainer`, `warning`,
    `warningContainer`, `glassFill`, `glassBorder`, `glowPrimary`,
    `glowSecondary`, `gridLine` (`Color`), `glassBlur` (`double`),
    `brandGradient` (`LinearGradient`); `VaiViverTokens.fromPalette(AppPalette)`.
  - `extension VaiViverThemeContext on BuildContext { VaiViverTokens get tokens }`.
  - `AppTheme.light()`, `AppTheme.dark()` → `ThemeData`;
    `AppTheme.overlayStyleFor(Brightness) → SystemUiOverlayStyle`.
  - Teste: `Widget themedApp({required Widget home, Map<String, WidgetBuilder> routes = const {}, ThemeMode themeMode = ThemeMode.light})`.

- [ ] **Step 1: Script de fontes e `.gitignore`**

`tool/fetch_fonts.sh`:

```bash
#!/usr/bin/env bash
# Downloads the app's fonts into assets/fonts/. They are git-ignored:
# Satoshi's license (ITF Free Font License) allows embedding it in the app
# but not making the font files available to others, and this repository
# is public. JetBrains Mono (OFL) is fetched the same way for consistency.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p assets/fonts/satoshi assets/fonts/jetbrains_mono

curl -fsSL -o "$tmp/satoshi.zip" \
  "https://api.fontshare.com/v2/fonts/download/satoshi"
for weight in Light Regular Medium Bold; do
  unzip -o -j -q "$tmp/satoshi.zip" \
    "Satoshi_Complete/Fonts/OTF/Satoshi-$weight.otf" -d assets/fonts/satoshi
done
unzip -o -j -q "$tmp/satoshi.zip" \
  "Satoshi_Complete/License/FFL.txt" -d assets/fonts/satoshi

curl -fsSL -o "$tmp/jetbrains_mono.zip" \
  "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
for weight in Regular Medium; do
  unzip -o -j -q "$tmp/jetbrains_mono.zip" \
    "fonts/ttf/JetBrainsMono-$weight.ttf" -d assets/fonts/jetbrains_mono
done
unzip -o -j -q "$tmp/jetbrains_mono.zip" "OFL.txt" -d assets/fonts/jetbrains_mono

echo "Fonts ready in assets/fonts/"
```

Run: `chmod +x tool/fetch_fonts.sh && tool/fetch_fonts.sh && ls assets/fonts/*`
Expected: `satoshi/` com `Satoshi-{Light,Regular,Medium,Bold}.otf` + `FFL.txt`;
`jetbrains_mono/` com `JetBrainsMono-{Regular,Medium}.ttf` + `OFL.txt`.
(Os caminhos dentro dos zips foram conferidos em 2026-09-27.)

Acrescente ao final de `.gitignore`:

```gitignore

# Fonts are downloaded by tool/fetch_fonts.sh (Satoshi's license forbids
# redistributing the files; this repository is public).
/assets/fonts/
```

Run: `git status --short assets` → Expected: saída vazia (ignorado).

- [ ] **Step 2: Declarar as fontes no `pubspec.yaml`**

Dentro da seção `flutter:` (logo abaixo de `uses-material-design: true`),
substitua o bloco comentado de exemplo de fontes por:

```yaml
  fonts:
    - family: Satoshi
      fonts:
        - asset: assets/fonts/satoshi/Satoshi-Light.otf
          weight: 300
        - asset: assets/fonts/satoshi/Satoshi-Regular.otf
          weight: 400
        - asset: assets/fonts/satoshi/Satoshi-Medium.otf
          weight: 500
        - asset: assets/fonts/satoshi/Satoshi-Bold.otf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/jetbrains_mono/JetBrainsMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/jetbrains_mono/JetBrainsMono-Medium.ttf
          weight: 500
```

Run: `.fvm/flutter_sdk/bin/flutter pub get` → Expected: sem erros.

- [ ] **Step 3: Escrever os testes que falham**

`test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/theme/app_palette.dart';
import 'package:vaiviver/core/theme/app_theme.dart';
import 'package:vaiviver/core/theme/app_typography.dart';
import 'package:vaiviver/core/theme/vaiviver_tokens.dart';

void main() {
  for (final (theme, palette) in [
    (AppTheme.light(), AppPalette.light),
    (AppTheme.dark(), AppPalette.dark),
  ]) {
    final name = palette.brightness.name;

    test('$name: color scheme and background come from the palette', () {
      expect(theme.brightness, palette.brightness);
      expect(theme.colorScheme.primary, palette.primary);
      expect(theme.colorScheme.onSurface, palette.onSurface);
      expect(theme.colorScheme.secondaryContainer, palette.primaryContainer);
      expect(theme.scaffoldBackgroundColor, palette.background);
    });

    test('$name: tokens extension carries the ambient effects', () {
      final tokens = theme.extension<VaiViverTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.glassFill, palette.glassFill);
      expect(tokens.success, palette.success);
      expect(tokens.brandGradient.colors, [
        palette.gradientStart,
        palette.gradientEnd,
      ]);
    });

    test('$name: Satoshi everywhere, thin display type, bold titles', () {
      expect(theme.textTheme.bodyMedium!.fontFamily, AppTypography.sans);
      expect(theme.textTheme.displaySmall!.fontWeight, FontWeight.w300);
      expect(theme.textTheme.headlineMedium!.fontWeight, FontWeight.w300);
      expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w700);
    });
  }

  group('VaiViverTokens.lerp', () {
    final light = VaiViverTokens.fromPalette(AppPalette.light);
    final dark = VaiViverTokens.fromPalette(AppPalette.dark);

    test('t=0 and t=1 return each side', () {
      expect(light.lerp(dark, 0).success, light.success);
      expect(light.lerp(dark, 1).success, dark.success);
      expect(light.lerp(dark, 1).glassFill, dark.glassFill);
      expect(
        light.lerp(dark, 1).brandGradient.colors,
        dark.brandGradient.colors,
      );
    });

    test('null other keeps this', () {
      expect(light.lerp(null, 0.5), same(light));
    });
  });

  testWidgets('enabled ElevatedButton paints the brand gradient; '
      'disabled one does not', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              ElevatedButton(
                key: const Key('on'),
                onPressed: () {},
                child: const Text('on'),
              ),
              const ElevatedButton(
                key: Key('off'),
                onPressed: null,
                child: Text('off'),
              ),
            ],
          ),
        ),
      ),
    );

    Gradient? backgroundGradientOf(String key) {
      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(DecoratedBox),
        ),
      );
      return boxes
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .first
          .gradient;
    }

    final tokens = AppTheme.light().extension<VaiViverTokens>()!;
    expect(backgroundGradientOf('on'), tokens.brandGradient);
    expect(backgroundGradientOf('off'), isNull);
  });
}
```

Em `test/main_test.dart`, acrescente os imports
`package:flutter/material.dart`,
`package:vaiviver/core/theme/app_palette.dart`,
`package:vaiviver/core/theme/vaiviver_tokens.dart` e
`package:vaiviver/features/home/home_screen.dart`, e este teste ao final de
`main()`:

```dart
  testWidgets('follows the system light/dark setting', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(onboardingComplete: true),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const VaiViverApp(),
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(HomeScreen)));
    expect(theme.brightness, Brightness.dark);
    expect(
      theme.extension<VaiViverTokens>()!.glassFill,
      AppPalette.dark.glassFill,
    );
  });
```

- [ ] **Step 4: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/theme/app_theme_test.dart test/main_test.dart`
Expected: FAIL. `app_theme_test` não compila (arquivos ausentes). O novo teste
de `main_test` falha porque o tema continua claro.

- [ ] **Step 5: Implementar dimensões e tipografia**

`lib/core/theme/app_dimens.dart`:

```dart
/// Spacing scale (4dp grid) shared by every screen.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Corner radii.
abstract final class AppRadius {
  static const card = 16.0;
}
```

`lib/core/theme/app_typography.dart`:

```dart
import 'package:flutter/material.dart';

/// Font families and the text-style tweaks that give the app krython.com's
/// look: thin large type, bold titles, airy body text, mono accents.
abstract final class AppTypography {
  static const sans = 'Satoshi';
  static const monoFamily = 'JetBrainsMono';

  /// Terminal-style labels (TerminalLabel, StatusPill, stat captions).
  /// Color is applied where it is used.
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static TextTheme refine(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w300,
      letterSpacing: -1,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      height: 1.15,
    ),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w500),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
    labelLarge: base.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
  );
}
```

- [ ] **Step 6: Implementar os tokens**

`lib/core/theme/vaiviver_tokens.dart`:

```dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Design tokens Material's ColorScheme has no slot for: status colors, the
/// glass/glow/grid ambient effects and the brand gradient.
///
/// Registered as a ThemeExtension so widgets read it from the theme
/// (`context.tokens`) and it animates with the theme: when the system
/// switches light <-> dark, MaterialApp tweens ThemeData and calls [lerp].
@immutable
class VaiViverTokens extends ThemeExtension<VaiViverTokens> {
  const VaiViverTokens({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.glassFill,
    required this.glassBorder,
    required this.glassBlur,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.gridLine,
    required this.brandGradient,
  });

  factory VaiViverTokens.fromPalette(AppPalette p) => VaiViverTokens(
    success: p.success,
    successContainer: p.successContainer,
    warning: p.warning,
    warningContainer: p.warningContainer,
    glassFill: p.glassFill,
    glassBorder: p.glassBorder,
    glassBlur: 16,
    glowPrimary: p.glowPrimary,
    glowSecondary: p.glowSecondary,
    gridLine: p.gridLine,
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [p.gradientStart, p.gradientEnd],
    ),
  );

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color glassFill;
  final Color glassBorder;

  /// Backdrop blur sigma, in logical pixels.
  final double glassBlur;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color gridLine;
  final LinearGradient brandGradient;

  @override
  VaiViverTokens copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? glassFill,
    Color? glassBorder,
    double? glassBlur,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? gridLine,
    LinearGradient? brandGradient,
  }) => VaiViverTokens(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    glassFill: glassFill ?? this.glassFill,
    glassBorder: glassBorder ?? this.glassBorder,
    glassBlur: glassBlur ?? this.glassBlur,
    glowPrimary: glowPrimary ?? this.glowPrimary,
    glowSecondary: glowSecondary ?? this.glowSecondary,
    gridLine: gridLine ?? this.gridLine,
    brandGradient: brandGradient ?? this.brandGradient,
  );

  @override
  VaiViverTokens lerp(covariant VaiViverTokens? other, double t) {
    if (other == null) return this;
    return VaiViverTokens(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t)!,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      brandGradient: LinearGradient.lerp(
        brandGradient,
        other.brandGradient,
        t,
      )!,
    );
  }
}

extension VaiViverThemeContext on BuildContext {
  /// The VaiViver tokens of the nearest theme.
  VaiViverTokens get tokens {
    final tokens = Theme.of(this).extension<VaiViverTokens>();
    assert(
      tokens != null,
      'VaiViverTokens missing from the theme: build the MaterialApp with '
      'AppTheme.light()/AppTheme.dark() (in tests, use themedApp()).',
    );
    return tokens!;
  }
}
```

- [ ] **Step 7: Implementar o `AppTheme`**

`lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_dimens.dart';
import 'app_palette.dart';
import 'app_typography.dart';
import 'vaiviver_tokens.dart';

/// Builds the app's ThemeData from [AppPalette]: palette -> ColorScheme +
/// VaiViverTokens -> component themes. Widgets only ever see the result.
abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  /// Status/navigation bar icons readable over the app background. The bars
  /// themselves stay transparent: the app draws edge-to-edge.
  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return base.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    );
  }

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      // FilledButton.tonal uses these: indigo chips, like krython's tags.
      secondaryContainer: p.primaryContainer,
      onSecondaryContainer: p.onPrimaryContainer,
      tertiary: p.tertiary,
      onTertiary: p.onTertiary,
      error: p.error,
      onError: p.onError,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      surfaceContainerHighest: p.surfaceContainerHighest,
      outline: p.outline,
      outlineVariant: p.outlineVariant,
    );
    final tokens = VaiViverTokens.fromPalette(p);
    final base = ThemeData(colorScheme: scheme, fontFamily: AppTypography.sans);
    final textTheme = AppTypography.refine(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyleFor(p.brightness),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: p.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _gradientButtonStyle(p, tokens, textTheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.outlineVariant,
        space: AppSpacing.xl,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Primary call to action: a pill filled with the brand gradient. Living in
  /// the theme, it reaches every ElevatedButton with no call-site changes.
  /// backgroundBuilder paints over the Material's ink splash, so the pressed
  /// feedback is drawn here as well.
  static ButtonStyle _gradientButtonStyle(
    AppPalette p,
    VaiViverTokens tokens,
    TextTheme textTheme,
  ) {
    return ElevatedButton.styleFrom(
      foregroundColor: p.onPrimary,
      disabledForegroundColor: p.onSurface.withValues(alpha: 0.38),
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      minimumSize: const Size(64, 52),
      shape: const StadiumBorder(),
      textStyle: textTheme.labelLarge,
    ).copyWith(
      backgroundBuilder: (context, states, child) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        return DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            gradient: disabled ? null : tokens.brandGradient,
            color: disabled ? p.onSurface.withValues(alpha: 0.12) : null,
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: pressed
                  ? p.onPrimary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 8: Ligar o tema no app**

Em `lib/main.dart`, importe `core/theme/app_theme.dart` e, dentro de
`VaiViverApp.build`, acrescente ao `MaterialApp` (logo após `locale:`):

```dart
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
```

- [ ] **Step 9: Helper de teste e migração dos wrappers**

`test/helpers/themed_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:vaiviver/core/theme/app_theme.dart';

/// A MaterialApp with the real VaiViver theme. Every widget test that renders
/// app UI must use it: the design-system widgets read VaiViverTokens from the
/// theme and assert it is there.
Widget themedApp({
  required Widget home,
  Map<String, WidgetBuilder> routes = const {},
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: home,
    routes: routes,
  );
}
```

Troque todo `MaterialApp(...)` dos testes de feature por `themedApp(...)`,
importando `'../../helpers/themed_app.dart'`:

- `home_screen_test.dart`, `_wrap` inteiro:

```dart
Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: themedApp(
      home: child,
      routes: {
        '/settings': (_) => const Scaffold(body: Text('settings-stub')),
        '/permissions': (_) => const Scaffold(body: Text('permissions-stub')),
      },
    ),
  );
}
```

- `onboarding_flow_screen_test.dart`: no primeiro teste e em `_wrap`,
  `child: themedApp(home: const OnboardingFlowScreen())`.
- `permissions_screen_test.dart`, nos dois testes:
  `child: themedApp(home: const PermissionsScreen())`.
- `settings_screen_test.dart`, nos dois testes:
  `child: themedApp(home: const SettingsScreen())`.

Run: `grep -rn "MaterialApp(" test`
Expected: só `test/helpers/themed_app.dart` e o teste de botão em
`test/core/theme/app_theme_test.dart`.

- [ ] **Step 10: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test`
Expected: PASS, a suíte inteira, incluindo os testes novos.

- [ ] **Step 11: Formatar, analisar e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze`
Expected: `No issues found!`. **Não commitar.**

---

### Task 3: Primitivos visuais (fundo ambiente, vidro, terminal, pílula, gradiente, estatística)

**Files:**
- Create: `lib/core/ui/ambient_background.dart`, `lib/core/ui/glass_card.dart`,
  `lib/core/ui/terminal_label.dart`, `lib/core/ui/status_pill.dart`,
  `lib/core/ui/gradient_text.dart`, `lib/core/ui/stat_value.dart`
- Test: `test/core/ui/primitives_test.dart`

**Interfaces:**
- Consumes: `context.tokens`, `AppSpacing`, `AppRadius`, `AppTypography.mono` (Task 2); `themedApp` (teste).
- Produces:
  - `AmbientBackground({required Widget child})`
  - `GlassCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg), VoidCallback? onTap})`
  - `TerminalLabel(String command)`: renderiza `~/vaiviver $ <command>`, fora da semântica
  - `enum PillTone { success, warning }`; `StatusPill({required String label, required PillTone tone})`
  - `GradientText(String text, {TextStyle? style, TextAlign? textAlign})`
  - `StatValue({required String value, required String label, String? unit})`:
    rótulo semântico `'$label: $value'` ou `'$label: $value $unit'`

- [ ] **Step 1: Escrever os testes que falham**

`test/core/ui/primitives_test.dart`:

```dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/theme/app_palette.dart';
import 'package:vaiviver/core/theme/vaiviver_tokens.dart';
import 'package:vaiviver/core/ui/ambient_background.dart';
import 'package:vaiviver/core/ui/glass_card.dart';
import 'package:vaiviver/core/ui/stat_value.dart';
import 'package:vaiviver/core/ui/status_pill.dart';
import 'package:vaiviver/core/ui/terminal_label.dart';

import '../../helpers/themed_app.dart';

Widget _host(Widget child) =>
    themedApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('AmbientBackground paints the theme background behind its child', (
    tester,
  ) async {
    for (final (mode, palette) in [
      (ThemeMode.light, AppPalette.light),
      (ThemeMode.dark, AppPalette.dark),
    ]) {
      await tester.pumpWidget(
        themedApp(
          themeMode: mode,
          home: const AmbientBackground(child: Text('conteúdo')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('conteúdo'), findsOneWidget);
      final background = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AmbientBackground),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((background.decoration as BoxDecoration).color, palette.background);
    }
  });

  testWidgets('GlassCard blurs what is behind it', (tester) async {
    await tester.pumpWidget(_host(const GlassCard(child: Text('vidro'))));

    final filter = tester.widget<BackdropFilter>(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(BackdropFilter),
      ),
    );
    expect(filter.filter, isA<ImageFilter>());
    expect(find.text('vidro'), findsOneWidget);
  });

  testWidgets('GlassCard is tappable only when onTap is set', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassCard(onTap: () => taps++, child: const Text('tocável')),
            const GlassCard(child: Text('estático')),
          ],
        ),
      ),
    );

    await tester.tap(find.text('tocável'));
    expect(taps, 1);

    final staticInkWell = tester.widget<InkWell>(
      find.ancestor(of: find.text('estático'), matching: find.byType(InkWell)),
    );
    expect(staticInkWell.onTap, isNull);
  });

  testWidgets('TerminalLabel renders a prompt and is hidden from screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TerminalLabel('status')));

    expect(find.text('~/vaiviver \$ status'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('vaiviver')), findsNothing);
  });

  testWidgets('StatusPill uses the success/warning token colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusPill(label: 'ativada', tone: PillTone.success),
            StatusPill(label: 'pendente', tone: PillTone.warning),
          ],
        ),
      ),
    );

    final tokens = VaiViverTokens.fromPalette(AppPalette.light);
    Color? textColor(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(textColor('ativada'), tokens.success);
    expect(textColor('pendente'), tokens.warning);
  });

  testWidgets('StatValue reads as one sentence and paints a gradient number', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const StatValue(
          value: '5',
          unit: 'min',
          label: 'Minutos de scroll evitados hoje',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Minutos de scroll evitados hoje: 5 min'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(StatValue),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/ui/primitives_test.dart`
Expected: FAIL com erro de compilação (os widgets não existem).

- [ ] **Step 3: Implementar `AmbientBackground`**

`lib/core/ui/ambient_background.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/vaiviver_tokens.dart';

/// The app's backdrop: theme background, a faint "matrix" grid and two soft
/// glows (cyan top-right, violet bottom-left). GlassCards blur this, which
/// is what makes the glass visible — over a flat color it would look like a
/// plain grey card. Static on purpose: no decorative motion.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GridPainter(
                  color: tokens.gridLine,
                  spacing: AppSpacing.xxl,
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: tokens.glowPrimary, diameter: 320),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(color: tokens.glowSecondary, diameter: 360),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}
```

- [ ] **Step 4: Implementar `GlassCard`**

`lib/core/ui/glass_card.dart`:

```dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/vaiviver_tokens.dart';

/// Frosted-glass surface: blurs what is behind it (the AmbientBackground grid
/// and glows), tints it with the glass fill and draws a hairline border.
/// Tappable when [onTap] is set.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.card);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.glassBlur,
          sigmaY: tokens.glassBlur,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: radius,
              border: Border.all(color: tokens.glassBorder),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implementar `TerminalLabel`, `StatusPill` e `GradientText`**

`lib/core/ui/terminal_label.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// A shell-prompt style section label, e.g. `~/vaiviver $ status`.
/// Decorative, so screen readers skip it.
class TerminalLabel extends StatelessWidget {
  const TerminalLabel(this.command, {super.key});

  final String command;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          style: AppTypography.mono.copyWith(color: scheme.onSurfaceVariant),
          children: [
            TextSpan(
              text: '~/vaiviver',
              style: TextStyle(color: scheme.primary),
            ),
            const TextSpan(text: ' \$ '),
            TextSpan(
              text: command,
              style: TextStyle(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/core/ui/status_pill.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/vaiviver_tokens.dart';

enum PillTone { success, warning }

/// Small rounded-full status tag (krython's `rounded-full px-2.5 py-0.5`).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, foreground) = switch (tone) {
      PillTone.success => (tokens.successContainer, tokens.success),
      PillTone.warning => (tokens.warningContainer, tokens.warning),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: background,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          label,
          style: AppTypography.mono.copyWith(
            color: foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

`lib/core/ui/gradient_text.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/vaiviver_tokens.dart';

/// Text filled with the brand gradient (CSS `bg-clip-text` equivalent).
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final gradient = context.tokens.brandGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          gradient.createShader(Offset.zero & bounds.size),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
```

- [ ] **Step 6: Implementar `StatValue`**

`lib/core/ui/stat_value.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'gradient_text.dart';

/// A big thin gradient number with a mono caption. Screen readers hear it as
/// one sentence ("Reels bloqueados hoje: 4"), and tests find it by that label.
class StatValue extends StatelessWidget {
  const StatValue({
    super.key,
    required this.value,
    required this.label,
    this.unit,
  });

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      container: true,
      label: unit == null ? '$label: $value' : '$label: $value $unit',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GradientText(value, style: theme.textTheme.displaySmall),
              if (unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  unit!,
                  style: theme.textTheme.titleMedium?.copyWith(color: muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.mono.copyWith(color: muted)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/ui/primitives_test.dart`
Expected: PASS.

- [ ] **Step 8: Formatar, analisar, rodar a suíte e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. **Não commitar.**

---

### Task 4: `AppScreen`, `ResponsiveBody` e a matriz de layout

**Files:**
- Create: `lib/core/ui/app_screen.dart`, `lib/core/ui/responsive_body.dart`,
  `test/helpers/phone_viewport.dart`
- Test: `test/core/ui/app_screen_test.dart`, `test/core/ui/responsive_body_test.dart`

**Interfaces:**
- Consumes: `AmbientBackground` (Task 3), `AppTheme.overlayStyleFor`, `AppSpacing` (Task 2).
- Produces:
  - `AppScreen({required Widget body, String? title, List<Widget>? actions})`:
    `AmbientBackground` → `Scaffold` transparente → `AppBar` só se houver `title`.
  - `ResponsiveBody({required Widget child, Widget? bottomAction, bool centerContent = false})`;
    `ResponsiveBody.maxContentWidth` = 560.
  - Teste: `class PhoneViewport` (`name`, `size`, `textScale`, `statusBar`, `navBar`),
    `const List<PhoneViewport> phoneViewports`,
    `void applyViewport(WidgetTester, PhoneViewport)`,
    `Future<void> expectContentFitsScreen(WidgetTester, PhoneViewport)`.

- [ ] **Step 1: Helper da matriz de layout**

`test/helpers/phone_viewport.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone configuration for layout tests: logical size, system font scale
/// and the system bars the app draws behind (it is edge-to-edge).
class PhoneViewport {
  const PhoneViewport(
    this.name,
    this.size, {
    this.textScale = 1.0,
    this.statusBar = 36,
    this.navBar = 24,
  });

  final String name;
  final Size size;
  final double textScale;
  final double statusBar;
  final double navBar;

  @override
  String toString() =>
      '$name ${size.width.toInt()}x${size.height.toInt()} @${textScale}x';
}

/// Phones every screen must fit: a common Xiaomi size, MIUI's large font
/// settings, a compact screen, 3-button navigation and landscape.
const phoneViewports = <PhoneViewport>[
  PhoneViewport('xiaomi', Size(393, 873)),
  PhoneViewport('xiaomi', Size(393, 873), textScale: 1.5),
  PhoneViewport('xiaomi', Size(393, 873), textScale: 2.0),
  PhoneViewport('compact', Size(360, 640), textScale: 1.5),
  PhoneViewport('compact-3-button-nav', Size(360, 640), navBar: 48),
  PhoneViewport('landscape', Size(873, 393), statusBar: 24, navBar: 16),
];

/// Makes the test window look like [v]. Call before pumpWidget.
void applyViewport(WidgetTester tester, PhoneViewport v) {
  const dpr = 3.0;
  tester.view.physicalSize = v.size * dpr;
  tester.view.devicePixelRatio = dpr;
  final insets = FakeViewPadding(
    top: v.statusBar * dpr,
    bottom: v.navBar * dpr,
  );
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.platformDispatcher.textScaleFactorTestValue = v.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Iterable<Rect> _onScreenTextRects(WidgetTester tester, Size screen) sync* {
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    // Other PageView pages sit fully left/right of the screen.
    if (rect.right <= 0 || rect.left >= screen.width) continue;
    yield rect;
  }
}

/// Fails if any text starts under the status bar or spills past the side
/// edges, or if — after scrolling every vertical scrollable to its end —
/// some text still ends under the navigation bar (it could never be read).
///
/// This catches content that silently runs off-screen without a RenderFlex
/// overflow error (e.g. a ListTile squeezed into an Expanded). The test font
/// is wider than Satoshi, so these checks are pessimistic — a safety margin.
Future<void> expectContentFitsScreen(
  WidgetTester tester,
  PhoneViewport v,
) async {
  const tolerance = 0.5;
  for (final rect in _onScreenTextRects(tester, v.size)) {
    expect(
      rect.top,
      greaterThanOrEqualTo(v.statusBar - tolerance),
      reason: 'text at $rect starts under the status bar on $v',
    );
    expect(
      rect.left,
      greaterThanOrEqualTo(-tolerance),
      reason: 'text at $rect spills past the left edge on $v',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(v.size.width + tolerance),
      reason: 'text at $rect spills past the right edge on $v',
    );
  }

  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.axis == Axis.vertical) {
      position.jumpTo(position.maxScrollExtent);
    }
  }
  await tester.pump();

  final bottoms = _onScreenTextRects(tester, v.size).map((r) => r.bottom);
  final lowest = bottoms.isEmpty ? 0.0 : bottoms.reduce(math.max);
  expect(
    lowest,
    lessThanOrEqualTo(v.size.height - v.navBar + tolerance),
    reason: 'content ends at $lowest, under the navigation bar on $v',
  );
}
```

- [ ] **Step 2: Escrever os testes que falham**

`test/core/ui/app_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/ui/ambient_background.dart';
import 'package:vaiviver/core/ui/app_screen.dart';

import '../../helpers/themed_app.dart';

void main() {
  testWidgets('shows an AppBar only when titled', (tester) async {
    await tester.pumpWidget(
      themedApp(home: const AppScreen(title: 'Título', body: SizedBox())),
    );
    expect(find.widgetWithText(AppBar, 'Título'), findsOneWidget);

    await tester.pumpWidget(themedApp(home: const AppScreen(body: SizedBox())));
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('paints the ambient background behind a transparent Scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(themedApp(home: const AppScreen(body: SizedBox())));

    expect(find.byType(AmbientBackground), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );
  });

  testWidgets('status bar icons follow the theme', (tester) async {
    await tester.pumpWidget(themedApp(home: const AppScreen(body: SizedBox())));
    final lightRegion = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(lightRegion.value.statusBarIconBrightness, Brightness.dark);

    await tester.pumpWidget(
      themedApp(
        themeMode: ThemeMode.dark,
        home: const AppScreen(body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    final darkRegion = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(darkRegion.value.statusBarIconBrightness, Brightness.light);
  });
}
```

`test/core/ui/responsive_body_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/ui/app_screen.dart';
import 'package:vaiviver/core/ui/responsive_body.dart';

import '../../helpers/phone_viewport.dart';
import '../../helpers/themed_app.dart';

final _longText = List.filled(
  12,
  'Necessária para detectar Reels e medir a rolagem do Feed.',
).join(' ');

void main() {
  group('keeps content on screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('long content + pinned action on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          themedApp(
            home: AppScreen(
              body: ResponsiveBody(
                bottomAction: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Próximo'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const Text('Acessibilidade'), Text(_longText)],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });

      testWidgets('centered short content on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          themedApp(
            home: AppScreen(
              body: ResponsiveBody(
                centerContent: true,
                bottomAction: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Próximo'),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bem-vinda ao VaiViver'),
                    Text(
                      'O VaiViver bloqueia a aba Reels do Instagram e limita '
                      'quanto tempo você rola o Feed.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });

  testWidgets('content spans the width, capped at maxContentWidth', (
    tester,
  ) async {
    Future<double> contentWidthOn(PhoneViewport viewport) async {
      applyViewport(tester, viewport);
      await tester.pumpWidget(
        themedApp(
          home: const AppScreen(
            body: ResponsiveBody(
              child: SizedBox(key: Key('content'), height: 10),
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(const Key('content'))).width;
    }

    // Portrait: full width minus 16dp gutters on each side.
    expect(await contentWidthOn(phoneViewports.first), 393 - 32);
    // Landscape: capped so lines stay readable.
    expect(
      await contentWidthOn(phoneViewports.last),
      ResponsiveBody.maxContentWidth,
    );
  });

  testWidgets('centerContent centers short content in the safe area', (
    tester,
  ) async {
    applyViewport(tester, phoneViewports.first);
    await tester.pumpWidget(
      themedApp(
        home: const AppScreen(
          body: ResponsiveBody(centerContent: true, child: Text('meio')),
        ),
      ),
    );

    // Safe area 36..849; minus the 8/24 scroll padding -> 44..825.
    expect(tester.getCenter(find.text('meio')).dy, closeTo(434.5, 1));
  });
}
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/ui/app_screen_test.dart test/core/ui/responsive_body_test.dart`
Expected: FAIL com erro de compilação (`AppScreen`/`ResponsiveBody` não existem).

- [ ] **Step 4: Implementar `AppScreen`**

`lib/core/ui/app_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ambient_background.dart';

/// Chrome shared by every screen: ambient background behind a transparent
/// Scaffold, an optional AppBar and system bar icons that match the theme.
/// Put a [ResponsiveBody] in [body] so the content stays on screen.
class AppScreen extends StatelessWidget {
  const AppScreen({super.key, required this.body, this.title, this.actions});

  final Widget body;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(Theme.of(context).brightness),
      child: AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: title == null
              ? null
              : AppBar(title: Text(title!), actions: actions),
          body: body,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implementar `ResponsiveBody`**

`lib/core/ui/responsive_body.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Lays out a screen's content so it never runs off the screen:
/// - stays inside the system bars (the app draws edge-to-edge);
/// - scrolls when taller than the viewport (large system fonts, small
///   screens, landscape) instead of overflowing or clipping;
/// - caps line length at [maxContentWidth] on wide screens;
/// - pins an optional [bottomAction] (e.g. "Próximo") above the nav bar.
/// With [centerContent], short content is centered vertically and still
/// scrolls once it no longer fits.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.bottomAction,
    this.centerContent = false,
  });

  static const maxContentWidth = 560.0;
  static const _padding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.xl,
  );

  final Widget child;
  final Widget? bottomAction;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(
                  constraints.maxWidth - _padding.horizontal,
                  maxContentWidth,
                );
                final minHeight = centerContent
                    ? math.max(0.0, constraints.maxHeight - _padding.vertical)
                    : 0.0;
                return SingleChildScrollView(
                  padding: _padding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(
                        width: width,
                      ).copyWith(minHeight: minHeight),
                      child: centerContent ? Center(child: child) : child,
                    ),
                  ),
                );
              },
            ),
          ),
          if (bottomAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: SizedBox(width: double.infinity, child: bottomAction),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/core/ui/`
Expected: PASS. (Este layout foi prototipado contra a mesma matriz em
2026-09-27 e passou nos 6 viewports.)

- [ ] **Step 7: Formatar, analisar, rodar a suíte e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. **Não commitar.**

---

### Task 5: Permissões — `PermissionCard` e tela de Status das Permissões

**Files:**
- Create: `lib/features/permissions/permission_card.dart`
- Modify: `lib/features/permissions/accessibility_status_tile.dart`,
  `battery_optimization_status_tile.dart`, `autostart_ack_tile.dart`,
  `permissions_screen.dart`
- Test: `test/features/permissions/permissions_screen_test.dart`

**Interfaces:**
- Consumes: `GlassCard`, `StatusPill`/`PillTone`, `TerminalLabel` (Task 3);
  `AppScreen`, `ResponsiveBody` (Task 4); `AppSpacing`, `AppTypography` (Task 2);
  `phoneViewports`, `applyViewport`, `expectContentFitsScreen`, `themedApp` (testes).
- Produces: `PermissionCard({required String title, required bool granted, required String grantedLabel, required String explanation, String? detail, Widget? action})`,
  com `PermissionCard.pendingLabel` = `'pendente'` e rótulo semântico do
  cabeçalho `'$title: $statusLabel'`. As classes `AccessibilityStatusTile`,
  `BatteryOptimizationStatusTile` e `AutostartAckTile` **mantêm nome e
  construtor**, porque o onboarding e os testes dependem delas.

- [ ] **Step 1: Escrever os testes que falham**

Em `test/features/permissions/permissions_screen_test.dart`:

1. No teste `'shows granted/pending state for each permission'`, troque os dois
   `find.text(...)` por:

```dart
    expect(find.bySemanticsLabel('Acessibilidade: ativada'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Otimização de bateria: pendente'),
      findsOneWidget,
    );
```

2. Acrescente os imports `'../../helpers/phone_viewport.dart'` e estes testes
   ao final de `main()`:

```dart
  testWidgets('only a pending permission offers its fix button', (
    tester,
  ) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: false,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Granted battery: no fix button for it.
    expect(find.text('Pedir isenção'), findsNothing);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    expect(fakeRepo.openAccessibilitySettingsCallCount, 1);
  });

  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('with every permission pending on $viewport', (
        tester,
      ) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionsRepositoryProvider.overrideWithValue(
                FakePermissionsRepository(
                  status: const PermissionStatus(
                    accessibilityEnabled: false,
                    batteryOptimizationIgnored: false,
                    autostartAcknowledged: false,
                  ),
                ),
              ),
            ],
            child: themedApp(home: const PermissionsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/permissions/permissions_screen_test.dart`
Expected: FAIL. Os rótulos semânticos não existem (o `ListTile` junta título e
subtítulo num rótulo só) e não há botão 'Abrir configurações'. O grupo de layout
talvez já passe nesta tela, porque ela usa `ListView` sem padding explícito; ele
fica como guarda.

- [ ] **Step 3: Implementar `PermissionCard`**

`lib/features/permissions/permission_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/glass_card.dart';
import '../../core/ui/status_pill.dart';

/// One permission: title + granted/pending pill, a free-flowing explanation
/// (it may wrap to many lines — nothing here has a fixed height), an optional
/// monospace [detail] such as a settings path, and the fix-it [action] below
/// the text at full width instead of squeezed beside it.
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.title,
    required this.granted,
    required this.grantedLabel,
    required this.explanation,
    this.detail,
    this.action,
  });

  static const pendingLabel = 'pendente';

  final String title;
  final bool granted;
  final String grantedLabel;
  final String explanation;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = granted ? grantedLabel : pendingLabel;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: '$title: $statusLabel',
            excludeSemantics: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                StatusPill(
                  label: statusLabel,
                  tone: granted ? PillTone.success : PillTone.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail!,
              style: AppTypography.mono.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Reescrever os três tiles sobre o `PermissionCard`**

`accessibility_status_tile.dart`: o `build` passa a retornar
(o texto vem de `docs/design.md` §5, passo 1):

```dart
    return PermissionCard(
      title: 'Acessibilidade',
      granted: status.accessibilityEnabled,
      grantedLabel: 'ativada',
      explanation:
          'O VaiViver precisa ler a tela do Instagram pra saber quando você '
          'está na aba Reels ou rolando o Feed — ele nunca lê nada de outros '
          'apps.',
      action: status.accessibilityEnabled
          ? null
          : FilledButton.tonal(
              onPressed: () => ref
                  .read(permissionsViewModelProvider.notifier)
                  .openAccessibilitySettings(),
              child: const Text('Abrir configurações'),
            ),
    );
```

`battery_optimization_status_tile.dart`:

```dart
    return PermissionCard(
      title: 'Otimização de bateria',
      granted: status.batteryOptimizationIgnored,
      grantedLabel: 'isenta',
      explanation:
          'Sem isso o Android pode encerrar o VaiViver em segundo plano.',
      action: status.batteryOptimizationIgnored
          ? null
          : FilledButton.tonal(
              onPressed: () => ref
                  .read(permissionsViewModelProvider.notifier)
                  .openBatteryOptimizationSettings(),
              child: const Text('Pedir isenção'),
            ),
    );
```

`autostart_ack_tile.dart` (mantenha a key e a regra de só reagir a `true`):

```dart
    return PermissionCard(
      title: 'Autostart (Xiaomi/MIUI)',
      granted: status.autostartAcknowledged,
      grantedLabel: 'confirmado',
      explanation:
          'Sem o Autostart, o MIUI pode não religar o VaiViver depois que o '
          'celular reinicia. Não dá pra verificar isso automaticamente — '
          'ative em:',
      detail:
          'Configurações > Apps > Gerenciar apps > VaiViver > Autostart\n'
          'ou App Segurança > Permissões > Autostart',
      action: CheckboxListTile(
        key: const Key('autostart-ack-checkbox'),
        value: status.autostartAcknowledged,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Já fiz isso'),
        onChanged: (value) {
          if (value == true) {
            ref
                .read(permissionsViewModelProvider.notifier)
                .acknowledgeAutostart();
          }
        },
      ),
    );
```

Nos três arquivos, importe `'permission_card.dart'`.

- [ ] **Step 5: Reescrever a tela de permissões**

`permissions_screen.dart`, no `build` (importe `AppScreen`, `ResponsiveBody`,
`TerminalLabel` e `AppSpacing`):

```dart
    return AppScreen(
      title: 'Status das Permissões',
      body: statusAsync.when(
        data: (status) => ResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TerminalLabel('check permissions'),
              const SizedBox(height: AppSpacing.lg),
              AccessibilityStatusTile(status: status),
              const SizedBox(height: AppSpacing.md),
              BatteryOptimizationStatusTile(status: status),
              const SizedBox(height: AppSpacing.md),
              AutostartAckTile(status: status),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ResponsiveBody(
          child: Text('Erro ao carregar permissões: $err'),
        ),
      ),
    );
```

- [ ] **Step 6: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/permissions/ test/features/onboarding/`
Expected: PASS. O onboarding usa os mesmos tiles e continua verde.

- [ ] **Step 7: Formatar, analisar, rodar a suíte e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. **Não commitar.**

---

### Task 6: Configurações — formulário e tela

**Files:**
- Modify: `lib/features/settings/app_settings_form.dart`,
  `lib/features/settings/settings_screen.dart`
- Test: `test/features/settings/settings_screen_test.dart`

**Interfaces:**
- Consumes: `AppScreen`, `ResponsiveBody` (Task 4); `GlassCard`, `TerminalLabel` (Task 3);
  `AppSpacing`, `AppTypography` (Task 2); `SettingsViewModel` já existente
  (`setReelsBlockEnabled`, `setScrollLimitEnabled`, `setScrollLimitMinutes`).
- Produces: `AppSettingsForm` com a mesma API (sem parâmetros), agora sem
  `ListTile` com `trailing`. É reutilizado pelo passo 4 do onboarding (Task 8).

- [ ] **Step 1: Escrever o teste que falha**

Em `settings_screen_test.dart`, importe `'../../helpers/phone_viewport.dart'` e
acrescente ao final de `main()`:

```dart
  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(
                FakeSettingsRepository(),
              ),
            ],
            child: themedApp(home: const SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/settings/settings_screen_test.dart`
Expected: FAIL em parte dos viewports com
`content ends at …, under the navigation bar`. O
`ListView(padding: EdgeInsets.all(16))` não soma a barra de navegação.

- [ ] **Step 3: Reescrever o formulário**

`app_settings_form.dart` (importe `AppSpacing` e `AppTypography`): troque o
`Column` do `data:` por:

```dart
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('reels-block-switch'),
            title: const Text('Bloquear aba Reels'),
            value: settings.reelsBlockEnabled,
            onChanged: (value) => ref
                .read(settingsViewModelProvider.notifier)
                .setReelsBlockEnabled(value),
          ),
          SwitchListTile(
            key: const Key('scroll-limit-switch'),
            title: const Text('Limite de scroll no Feed'),
            value: settings.scrollLimitEnabled,
            onChanged: (value) => ref
                .read(settingsViewModelProvider.notifier)
                .setScrollLimitEnabled(value),
          ),
          _MinutesStepper(
            minutes: settings.scrollLimitMinutes,
            enabled: settings.scrollLimitEnabled,
            onChanged: (minutes) => ref
                .read(settingsViewModelProvider.notifier)
                .setScrollLimitMinutes(minutes),
          ),
        ],
      ),
```

e acrescente no mesmo arquivo:

```dart
/// "Limite de scroll (minutos)" with −/+ buttons. A Row with an Expanded
/// label (not a ListTile trailing) so the label wraps under large fonts
/// instead of fighting the buttons for width.
class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({
    required this.minutes,
    required this.enabled,
    required this.onChanged,
  });

  final int minutes;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Limite de scroll (minutos)',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: enabled ? null : scheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
          IconButton.outlined(
            key: const Key('scroll-limit-decrement'),
            icon: const Icon(Icons.remove),
            onPressed: enabled && minutes > 1
                ? () => onChanged(minutes - 1)
                : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: Text(
              '$minutes',
              textAlign: TextAlign.center,
              style: AppTypography.mono.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: scheme.primary,
              ),
            ),
          ),
          IconButton.outlined(
            key: const Key('scroll-limit-increment'),
            icon: const Icon(Icons.add),
            onPressed: enabled ? () => onChanged(minutes + 1) : null,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Reescrever a tela de Configurações**

`settings_screen.dart`, no `build` (importe `AppScreen`, `ResponsiveBody`,
`GlassCard`, `TerminalLabel` e `AppSpacing`):

```dart
    final theme = Theme.of(context);
    return AppScreen(
      title: 'Configurações',
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TerminalLabel('config'),
            const SizedBox(height: AppSpacing.lg),
            const GlassCard(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppSettingsForm(),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              onTap: () => Navigator.of(context).pushNamed('/permissions'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verificar permissões',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
```

- [ ] **Step 5: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/settings/ test/features/onboarding/`
Expected: PASS. Os testes de toggle e de stepper continuam achando as keys.

- [ ] **Step 6: Formatar, analisar, rodar a suíte e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. **Não commitar.**

---

### Task 7: Home

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Test: `test/features/home/home_screen_test.dart`

**Interfaces:**
- Consumes: `AppScreen`, `ResponsiveBody` (Task 4); `GlassCard`, `TerminalLabel`,
  `StatValue` (Task 3); `context.tokens`, `AppSpacing` (Task 2).
- Produces: `HomeScreen` com a mesma API. Os textos 'Proteções ativas' e
  'Ação necessária' continuam como `Text`. As estatísticas passam a ser
  encontradas por rótulo semântico.

- [ ] **Step 1: Escrever os testes que falham**

Em `home_screen_test.dart`:

1. Troque **todas** as ocorrências (6 no arquivo) de
   `find.text('Reels bloqueados hoje: N')` e
   `find.text('Minutos de scroll evitados hoje: N min')` por
   `find.bySemanticsLabel(...)` com a mesma string. Exemplo:

```dart
    expect(find.bySemanticsLabel('Reels bloqueados hoje: 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Minutos de scroll evitados hoje: 5 min'),
      findsOneWidget,
    );
```

Run: `grep -n "find.text('Reels\|find.text('Minutos" test/features/home/home_screen_test.dart`
Expected: nenhuma linha.

2. Importe `'../../helpers/phone_viewport.dart'` e acrescente ao final de `main()`:

```dart
  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          _wrap(
            const HomeScreen(),
            overrides: [
              statsRepositoryProvider.overrideWithValue(
                FakeStatsRepository(
                  const DailyStats(
                    reelsBlockedCount: 128,
                    scrollSecondsSaved: 5400,
                  ),
                ),
              ),
              permissionsRepositoryProvider.overrideWithValue(
                FakePermissionsRepository(
                  status: const PermissionStatus(
                    accessibilityEnabled: false,
                    batteryOptimizationIgnored: true,
                    autostartAcknowledged: true,
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/home/home_screen_test.dart`
Expected: FAIL. Os rótulos semânticos das estatísticas não existem, e com fonte
2,0× o conteúdo termina sob a barra de navegação.

- [ ] **Step 3: Reescrever a Home**

Em `home_screen.dart`, importe `AppScreen`, `ResponsiveBody`, `GlassCard`,
`TerminalLabel`, `StatValue`, `AppSpacing` e `vaiviver_tokens.dart`. O `build`
de `_HomeScreenState` passa a ser:

```dart
  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsViewModelProvider);
    final stats = ref.watch(statsViewModelProvider);

    return AppScreen(
      title: 'VaiViver',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configurações',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TerminalLabel('status'),
            const SizedBox(height: AppSpacing.lg),
            permissions.when(
              data: (status) => _PermissionsStatusCard(status: status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erro ao carregar permissões: $err'),
            ),
            const SizedBox(height: AppSpacing.md),
            stats.when(
              data: (data) => _StatsCard(stats: data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erro ao carregar estatísticas: $err'),
            ),
          ],
        ),
      ),
    );
  }
```

Substitua `_PermissionsStatusCard.build` por:

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final allGranted = status.allGranted;
    final (foreground, background) = allGranted
        ? (tokens.success, tokens.successContainer)
        : (tokens.warning, tokens.warningContainer);
    return GlassCard(
      onTap: () => Navigator.of(context).pushNamed('/permissions'),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                allGranted
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allGranted ? 'Proteções ativas' : 'Ação necessária',
                  style: theme.textTheme.titleMedium,
                ),
                if (!allGranted)
                  Text(
                    'Verifique as permissões pendentes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
```

Substitua `_StatsCard.build` por (o `Wrap` joga a segunda estatística para a
linha de baixo quando não cabe lado a lado):

```dart
  @override
  Widget build(BuildContext context) {
    final minutesSaved = (stats.scrollSecondsSaved / 60).floor();
    return GlassCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          StatValue(
            value: '${stats.reelsBlockedCount}',
            label: 'Reels bloqueados hoje',
          ),
          StatValue(
            value: '$minutesSaved',
            unit: 'min',
            label: 'Minutos de scroll evitados hoje',
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/home/ test/main_test.dart test/features/onboarding/`
Expected: PASS. `main_test` e o onboarding terminam na Home e continuam achando
o título 'VaiViver'.

- [ ] **Step 5: Formatar, analisar, rodar a suíte e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. **Não commitar.**

---

### Task 8: Onboarding (o bug reportado) e tela de carregamento do app

**Files:**
- Modify: `lib/features/onboarding/onboarding_flow_screen.dart`,
  `lib/features/onboarding/welcome_step.dart`, `lib/main.dart` (`AppStartupGate`)
- Test: `test/features/onboarding/onboarding_flow_screen_test.dart`

**Interfaces:**
- Consumes: `AppScreen`, `ResponsiveBody` (Task 4); `GlassCard`, `TerminalLabel`,
  `GradientText` (Task 3); tiles de permissão (Task 5); `AppSettingsForm` (Task 6).
- Produces: `WelcomeStep({required VoidCallback onNext})`, com a mesma API. Os
  passos continuam dentro do `PageView` e com os mesmos botões
  ('Próximo'/'Concluir' como `ElevatedButton`).

- [ ] **Step 1: Escrever o teste que reproduz o bug**

Em `onboarding_flow_screen_test.dart`, importe `'../../helpers/phone_viewport.dart'`
e acrescente ao final de `main()`:

```dart
  // Regression for the reported bug: permission explanations ran off the
  // screen (under the status bar, and past the bottom with large fonts).
  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('every step on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          _wrap(
            FakePermissionsRepository(
              status: const PermissionStatus(
                accessibilityEnabled: false,
                batteryOptimizationIgnored: false,
                autostartAcknowledged: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
        for (var page = 0; page < 5; page++) {
          pages.jumpToPage(page);
          await tester.pumpAndSettle();
          await expectContentFitsScreen(tester, viewport);
        }
      });
    }
  });
```

- [ ] **Step 2: Rodar e ver falhar (reprodução do bug)**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/onboarding/onboarding_flow_screen_test.dart`
Expected: FAIL em **todos** os viewports com
`text at Rect.fromLTRB(…, 32.0, …) starts under the status bar`. Com fonte ≥1,5×,
aparece também `A RenderFlex overflowed … WelcomeStep`.

- [ ] **Step 3: Reescrever a `WelcomeStep`**

`welcome_step.dart` (importe `ResponsiveBody`, `TerminalLabel`, `GradientText`
e `AppSpacing`):

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveBody(
      centerContent: true,
      bottomAction: ElevatedButton(
        onPressed: onNext,
        child: const Text('Próximo'),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalLabel('init'),
          const SizedBox(height: AppSpacing.lg),
          GradientText(
            'Bem-vinda ao VaiViver',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'O VaiViver bloqueia a aba Reels do Instagram e limita quanto tempo '
            'você rola o Feed. Para isso, ele precisa de algumas permissões — '
            'vamos te guiar por cada uma.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Reescrever o fluxo e o `_StepScaffold`**

Em `onboarding_flow_screen.dart` (importe `AppScreen`, `ResponsiveBody`,
`GlassCard`, `TerminalLabel` e `AppSpacing`), o `build` do state passa a ser:

```dart
  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(permissionsViewModelProvider);

    return AppScreen(
      body: statusAsync.when(
        data: (status) => PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            WelcomeStep(onNext: _goNext),
            _StepScaffold(
              step: 1,
              onNext: _goNext,
              canAdvance: status.accessibilityEnabled,
              child: AccessibilityStatusTile(status: status),
            ),
            _StepScaffold(
              step: 2,
              onNext: _goNext,
              child: BatteryOptimizationStatusTile(status: status),
            ),
            _StepScaffold(
              step: 3,
              onNext: _goNext,
              child: AutostartAckTile(status: status),
            ),
            _StepScaffold(
              step: 4,
              onNext: _finish,
              buttonLabel: 'Concluir',
              child: const GlassCard(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: AppSettingsForm(),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            ResponsiveBody(centerContent: true, child: Text('Erro: $err')),
      ),
    );
  }
```

e o `_StepScaffold` inteiro vira:

```dart
/// One onboarding step: a "setup n/4" prompt, the step's content (scrolls
/// when it doesn't fit) and the advance button pinned above the nav bar.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.step,
    required this.child,
    required this.onNext,
    this.buttonLabel = 'Próximo',
    this.canAdvance = true,
  });

  static const _stepCount = 4;

  final int step;
  final Widget child;
  final VoidCallback onNext;
  final String buttonLabel;
  final bool canAdvance;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody(
      bottomAction: ElevatedButton(
        onPressed: canAdvance ? onNext : null,
        child: Text(buttonLabel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TerminalLabel('setup $step/$_stepCount'),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
```

A SnackBar de erro de `_finish` continua funcionando. Agora existe um único
`Scaffold` (o do `AppScreen`) e os passos não são mais `Scaffold`s.

- [ ] **Step 5: Tela de carregamento/erro do app**

Em `lib/main.dart` (importe `AppScreen` e `ResponsiveBody`), no
`AppStartupGate.build`:

```dart
      loading: () => const AppScreen(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => AppScreen(
        body: ResponsiveBody(centerContent: true, child: Text('Erro: $err')),
      ),
```

- [ ] **Step 6: Rodar e ver passar**

Run: `.fvm/flutter_sdk/bin/flutter test test/features/onboarding/ test/main_test.dart`
Expected: PASS, incluindo os três testes antigos do onboarding (caminho
completo, bloqueio do passo de Acessibilidade, SnackBar de erro) e os 6
viewports do grupo novo.

- [ ] **Step 7: Formatar, analisar, rodar a suíte e parar para revisão**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. **Não commitar.**

---

### Task 9: Documentação e verificação no aparelho

**Files:**
- Modify: `docs/design.md` (nova §10 e um item em §9), `docs/requirements.md`
  (RNF09, RNF10), `docs/manual-test-checklist.md` (nova seção), `CLAUDE.md`

**Interfaces:**
- Consumes: tudo acima. Produces: nada de código.

- [ ] **Step 1: `docs/design.md`**

Em §9 "Estratégia de testes", acrescente o item:

```markdown
- **Layout (Flutter):** cada tela roda numa matriz de celulares
  (`test/helpers/phone_viewport.dart`: 360×640 e 393×873 dp, fonte até 2,0×,
  navegação por gestos e por 3 botões, paisagem) e o teste falha se algum texto
  ficar sob as barras do sistema ou fora de alcance mesmo rolando.
```

Ao final do arquivo, acrescente:

```markdown
## 10. Design system (visual)

**Referência:** o visual de krython.com: Satoshi com títulos finos, azul-ciano e
índigo sobre fundo quase branco (ou quase preto azulado no tema escuro), cards de
vidro fosco, brilhos ciano/violeta, gradientes e detalhes de terminal em fonte
mono. Animações decorativas ficaram de fora de propósito, porque o app é sobre
passar menos tempo olhando para a tela. Os temas claro e escuro seguem o sistema.

**Camadas de tokens (só a primeira tem valores hex):**

1. `AppPalette` (`lib/core/theme/app_palette.dart`): todas as cores cruas, uma
   instância clara e uma escura. Um teste garante contraste WCAG AA (texto
   ≥ 4,5:1, componentes ≥ 3:1). O ciano original do site (`#2B95D3`) não passa
   em texto, por isso é usado só no gradiente e no brilho.
2. `ColorScheme` + `VaiViverTokens` (`ThemeExtension`): o que cada cor significa.
   O que o Material não tem (sucesso/aviso, vidro, brilho, grade, gradiente) fica
   na extensão, que também faz a transição claro↔escuro via `lerp`.
3. `AppTheme`: temas de componente (botão principal com gradiente via
   `backgroundBuilder`, AppBar transparente etc.).

**Tipografia:** Satoshi (títulos grandes 300, títulos de card 700, corpo 400) e
JetBrains Mono nos rótulos estilo terminal. As fontes ficam fora do git: a
licença da Satoshi (ITF FFL) permite embutir a fonte no app mas não redistribuir
os arquivos, e o repositório é público. `tool/fetch_fonts.sh` baixa as duas.

**Componentes (`lib/core/ui/`):** `AppScreen` (fundo ambiente + Scaffold
transparente + AppBar), `ResponsiveBody` (área segura + scroll + largura máx.
560dp + ação fixa no rodapé), `GlassCard`, `TerminalLabel`, `StatusPill`,
`GradientText` e `StatValue`. Em `features/permissions/` fica o `PermissionCard`.

**Regra de responsividade:** toda tela é `AppScreen` + `ResponsiveBody`, e nenhum
conteúdo fica em `Column` de altura fixa sem scroll. O app é edge-to-edge (o
Android desenha atrás das barras do sistema), então a área segura é obrigatória.
Foi a falta dela, junto com passos do onboarding que não rolavam, que fez as
explicações das permissões passarem da tela.
```

- [ ] **Step 2: `docs/requirements.md`**

Na tabela de RNF, depois de RNF08, acrescente:

```markdown
| RNF09 | A interface segue um design system próprio (paleta, tipografia e componentes), com temas claro e escuro que acompanham a configuração do sistema; todo texto tem contraste mínimo WCAG AA (4,5:1). |
| RNF10 | Todo texto e todo controle permanecem visíveis e alcançáveis (rolando, se preciso), nunca sob as barras do sistema, em telas a partir de 360×640 dp, com a fonte do sistema em até 2,0×, em retrato ou paisagem. |
```

- [ ] **Step 3: `docs/manual-test-checklist.md`**

Ao final do arquivo, acrescente:

```markdown
## Visual e responsividade

19. Com o celular no tema claro, percorra onboarding (limpe os dados do app),
    Home, Configurações e Status das Permissões. Nenhum título pode ficar
    embaixo do relógio/câmera, e "Próximo"/"Concluir" ficam sempre acima da
    barra de navegação.
20. Com o app aberto, troque o celular para o tema escuro. O app deve
    acompanhar, com os textos legíveis sobre os cards de vidro.
21. Em Configurações do MIUI > Tela > Tamanho do texto, escolha o maior. Refaça o
    percurso do item 19: tudo deve ser alcançável rolando a tela, sem texto
    cortado nem sobreposto.
22. Se o launcher permitir, gire para paisagem (ou abra o VaiViver em tela
    dividida). O conteúdo deve rolar e o botão fixo do onboarding continuar
    visível.
```

- [ ] **Step 4: `CLAUDE.md`**

Depois da seção "Regras de trabalho", acrescente:

```markdown
## Setup

- Antes do primeiro `flutter test`/`build` num clone novo, rode
  `tool/fetch_fonts.sh`. As fontes (Satoshi, JetBrains Mono) ficam fora do git
  por causa da licença da Satoshi, e este repositório é público.
- Flutter via FVM: `.fvm/flutter_sdk/bin/flutter`.
```

- [ ] **Step 5: Verificação completa**

Run:

```bash
.fvm/flutter_sdk/bin/dart format --output=none --set-exit-if-changed lib test
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter build apk --debug
git status --short
```

Expected: format sem mudanças; `No issues found!`; todos os testes verdes; APK
gerado em `build/app/outputs/flutter-apk/app-debug.apk`. `git status` **não**
lista nada em `assets/fonts/`.

- [ ] **Step 6: Entregar para a Soraya**

**Não commitar.** Peça à Soraya que:
1. revise o diff no working tree;
2. instale o APK no celular e rode os itens 19 a 22 do checklist manual;
3. commite ela mesma se estiver tudo certo.
