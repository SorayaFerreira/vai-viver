# VaiViver — Documento de Design

> Documento vivo, escrito de forma incremental durante o brainstorming do projeto.
> Cada seção é registrada após ser validada em conversa com a autora do produto.

## 1. Contexto e Objetivo

O VaiViver é um aplicativo Android (Flutter/Dart) de uso **pessoal** (instalado via
sideload, sem publicação na Play Store), cujo objetivo é reduzir o tempo de tela da
usuária no Instagram, atacando dois comportamentos específicos:

1. **Consumo de Reels** — o app impede o uso da aba "Reels".
2. **Tempo excessivo no Feed** — o app impõe um limite diário de tempo com a aba
   Início do Instagram aberta, configurável pela usuária.

## 2. Decisões de Produto (Regras de Negócio)

Decisões já validadas em conversa:

- **Distribuição:** sideload pessoal. Sem restrições de política de loja — isso nos
  dá liberdade técnica total sobre como o Accessibility Service é usado.
- **Ação de "fechar o Instagram":** sempre `GLOBAL_ACTION_HOME` (leva para a tela
  inicial do Android). Não há tentativa de matar o processo do Instagram de fato —
  isso exigiria root ou configurar o VaiViver como Device Owner via ADB, o que foi
  descartado por ser mais invasivo/difícil de reverter.
- **Escopo do bloqueio de Reels:** somente a aba dedicada "Reels" da barra inferior.
  Reels misturados dentro do scroll do Feed **não** são tratados nesta versão.
- **Ação ao detectar a aba Reels:** `GLOBAL_ACTION_HOME` (sai do Instagram
  completamente, mesma ação usada no limite do Feed — consistência de UX).
- **Limite do Feed (mudança de 2026-09-28):** a regra anterior media só rolagem
  ativa, por sessão; não funcionou no aparelho e foi trocada por um limite
  **diário de tempo com a aba Início aberta**:
  - **O que conta:** todo o tempo com a aba Início selecionada na barra inferior
    (a lista do Feed e perfis/posts/comentários abertos a partir dela), rolando
    ou parada. Stories em tela cheia não contam (a barra some).
  - **Valor do limite:** 20 minutos por dia por padrão, **ajustável** (stepper de
    1 em 1 até 5 min, depois de 5 em 5).
  - **Reset:** à meia-noite (horário do aparelho). Sair e voltar ao Instagram não
    zera nada.
  - **Janela de 5 s:** com o limite estourado, ao **abrir** o Instagram (que
    sempre começa na Início) há 5 s para ir a Direct/Buscar/Perfil; voltar à
    Início no meio da sessão expulsa na hora. Assim as DMs continuam acessíveis.
- **Toggles independentes:** duas funcionalidades (Bloquear Reels / Limite diário no Feed)
  cada uma com seu próprio interruptor on/off, além do valor de tempo ajustável.
- **Estatísticas no MVP:** contadores diários simples — quantas vezes o Reels foi
  bloqueado hoje, quanto tempo de Feed foi usado e quantas saídas forçadas do Feed
  houve hoje. Sem histórico
  de longo prazo nesta versão.
- **Dispositivo de referência:** Android 13+, fabricante Xiaomi/Redmi/Poco
  (MIUI/HyperOS) — implica cuidados extras de onboarding para gerenciamento de
  bateria e "Autostart" (ver seções 4.2 e 5).

## 3. Arquitetura

### 3.1 Camadas

```
View (Flutter widgets)
   -> ViewModel (Riverpod Notifier — lógica de apresentação, estado observável)
      -> Repository (interface Dart: SettingsRepository, StatsRepository)
         -> Bridge nativo (MethodChannel)
            -> Serviço Android nativo (Kotlin) — AccessibilityService
```

- **MVVM** implementado com **Riverpod**: ViewModels são classes `Notifier` (ou
  `AsyncNotifier` quando envolvem leitura assíncrona via MethodChannel), injetadas
  via providers — sem depender de `BuildContext` para resolver dependências. Views
  são `ConsumerWidget`s que observam esses providers.
- **Repository Pattern:** `SettingsRepository` e `StatsRepository` são interfaces
  abstratas no lado Dart. As ViewModels nunca falam diretamente com o
  `MethodChannel` — falam com a interface do repositório. Isso torna as ViewModels
  100% testáveis com um repositório fake, sem precisar simular Android real nos
  testes unitários.

### 3.2 Padrões no lado nativo (Kotlin)

- **Strategy Pattern:** cada regra de bloqueio implementa uma interface comum
  `DetectionRule` (ex: `ReelsTabRule`, `FeedTimeLimitRule`). O `AccessibilityService`
  apenas despacha eventos para a lista de regras registradas — não conhece a lógica
  específica de cada uma. Adicionar uma regra nova no futuro (ex: bloquear a aba
  Explorar) é escrever uma nova classe e registrá-la, sem alterar o serviço
  (Open/Closed Principle).
- **Intervalos + prazo para medir tempo no Feed:** `FeedTimeTracker` soma
  intervalos com a aba Início na tela, marcados pelos eventos que o serviço já
  recebe (a mesma leitura que serve ao bloqueio de Reels — nenhuma leitura extra
  de tela). Um timer agendado para o instante do limite relê a tela uma vez,
  cobrindo o caso de ficar parada no Feed (sem eventos). `ACTION_SCREEN_OFF`
  fecha o intervalo para não contar tempo com a tela apagada.

## 4. Detecção técnica (Accessibility Service) e riscos conhecidos

### 4.1 Como funciona

- Declarado no `AndroidManifest.xml` com `android:canRetrieveWindowContent="true"`.
  **Ajuste em relação à primeira versão deste documento:** para saber quando a
  usuária *sai* do Instagram (e assim encerrar a sessão: janela de 5 s, contagem de
  bloqueios), o
  serviço precisa observar `TYPE_WINDOW_STATE_CHANGED` em nível de sistema, sem o
  filtro `android:packageNames`. Se esse filtro estivesse ativo, o Android
  simplesmente não entregaria nenhum evento assim que outro app entrasse em
  primeiro plano, e o serviço nunca saberia que a sessão do Instagram acabou.
  Isso significa que o VaiViver recebe o **nome do pacote** de qualquer app que
  entra em primeiro plano (necessário para detectar a troca), mas só inspeciona
  **conteúdo de tela** (a árvore de nós) quando esse pacote é
  `com.instagram.android` — para qualquer outro app, o evento é usado só para
  comparar o nome do pacote e descartado em seguida, nunca lido a fundo.
  Para eventos de outros apps, a janela ativa (`rootInActiveWindow`, uma chamada
  ao app em primeiro plano) só é consultada quando chega um
  `TYPE_WINDOW_STATE_CHANGED` de outro pacote;
  os `TYPE_WINDOW_CONTENT_CHANGED` de outros apps, que chegam várias vezes por
  segundo, são descartados pelo tipo, sem consulta (2026-10-02).
- Escuta `TYPE_WINDOW_STATE_CHANGED` / `TYPE_WINDOW_CONTENT_CHANGED` (para saber em
  que tela do Instagram a usuária está, e para detectar a saída do Instagram).
- **Identificação da aba Reels e da aba Feed:** inspeção da árvore de nós
  (`AccessibilityNodeInfo`) da janela ativa, procurando por `viewIdResourceName` ou
  `contentDescription` conhecidos do Instagram — obtidos por engenharia reversa da
  UI do app, já que não existe API pública/documentada para isso.

### 4.2 Riscos conhecidos (não eliminam o projeto, mas precisam ser aceitos)

- **Acoplamento a implementação não-contratual do Instagram:** o Instagram
  atualiza seu app com frequência e pode trocar identificadores internos sem
  aviso, quebrando a detecção silenciosamente. Mitigação: o Strategy Pattern
  isola cada regra, então corrigir um identificador quebrado é uma mudança
  pequena e localizada, não uma reescrita — mas o risco em si não é eliminável.
- **MIUI/HyperOS:** mesmo com a permissão de Acessibilidade concedida, o sistema
  pode (1) exigir reativação manual do serviço após reiniciar o celular, e (2)
  matar o serviço em background se "Autostart" não estiver habilitado. O app só
  consegue orientar esses passos — não pode forçá-los programaticamente.
- **Contagem de estatísticas em rajadas de eventos — corrigido:** nem
  `ReelsTabRule` nem `FeedTimeLimitRule` decidem quando incrementar as
  estatísticas — isso ficou centralizado no `VaiViverAccessibilityService`,
  que mantém uma trava (`countedThisSession`) garantindo no máximo um
  incremento por sessão, mesmo que múltiplos eventos de acessibilidade
  cheguem antes de `GLOBAL_ACTION_HOME` efetivamente levar o Instagram para
  segundo plano. `performGlobalAction(GLOBAL_ACTION_HOME)` continua sendo
  chamado a cada evento correspondente (inofensivo), só a contagem é única
  por sessão.
- **Fim de sessão por engano com teclado/notificações — corrigido
  (2026-09-28):** o Android também dispara `TYPE_WINDOW_STATE_CHANGED` para
  Dialogs de outros pacotes (teclado, painel de volume, bandeja de
  notificações), o que encerrava a sessão por engano. Agora o fim de sessão
  exige também que a janela ativa não seja mais do Instagram
  (`isLeavingInstagram`, comparando só nomes de pacote). Isso importa mais com
  a janela de 5 s: uma notificação não pode reabrir a janela.

## 5. Fluxo de Onboarding (permissões)

Um assistente passo-a-passo que só avança quando o essencial está resolvido, mas
que também precisa estar acessível **depois** da primeira abertura — não só no
primeiro uso — porque permissões podem ser revogadas manualmente ou "esquecidas"
pelo MIUI após reiniciar o celular.

**Telas:**

1. **Boas-vindas:** explica em 2-3 frases o que o app faz e por que vai pedir
   permissões incomuns.
2. **Passo 1 — Acessibilidade:** explica o motivo ("o VaiViver precisa ler a tela
   do Instagram pra saber quando você está na aba Reels ou rolando o Feed — ele
   nunca lê nada de outros apps"). Botão abre a tela de Configurações de
   Acessibilidade do Android. Ao voltar pro app, verificação automática (via
   bridge nativo) se o serviço já está ativo.
3. **Passo 2 — Otimização de bateria:** explica que sem isso o Android pode
   encerrar o VaiViver em segundo plano. Botão abre diretamente o diálogo do
   sistema para isentar o app da otimização de bateria. Verificação automática.
4. **Passo 3 — Autostart (específico Xiaomi/MIUI):** não existe um Intent
   confiável entre versões do MIUI/HyperOS para abrir essa tela direto — é
   instrução em texto ("Configurações > Apps > Gerenciar apps > VaiViver >
   Autostart" ou "App Segurança > Permissões > Autostart") com uma caixinha
   "Já fiz isso". Sem falsa verificação programática do que não é verificável.
5. **Passo 4 — Configuração inicial:** os dois toggles (Bloquear Reels / Limite
   diário no Feed) e o stepper "Minutos por dia no Feed" (padrão 20).
6. **Concluído** → tela principal (status/estatísticas).

**Reuso pós-onboarding:** os passos 2 a 4 também existem como uma tela
**"Status das Permissões"**, acessível a qualquer momento pela tela principal —
necessário porque essas permissões podem "cair" sozinhas (reboot no MIUI,
revogação manual etc.).

## 6. Telas principais do app

Pós-onboarding, o app fica com só 3 telas, deliberadamente simples. Sem barra de
navegação inferior — poucas telas, então `Navigator.push` simples já resolve.

1. **Home / Status** (tela inicial):
   - Card de status: "✅ Proteções ativas" ou "⚠️ Ação necessária" — se qualquer
     permissão cair, aparece aqui em destaque; toque leva à tela de Permissões.
   - Card de estatísticas do dia: "Tempo no Feed hoje: N de 20 min" / "Reels
     bloqueados hoje" / "Saídas forçadas do Feed hoje".
   - Ícone de engrenagem na AppBar → Configurações.

2. **Configurações:**
   - Toggle "Bloquear aba Reels".
   - Toggle "Limite diário no Feed".
   - Stepper "Minutos por dia no Feed" — habilitado só se o
     toggle acima estiver ligado.
   - Atalho "Verificar permissões" → tela de Status das Permissões.

3. **Status das Permissões** (reaproveita os passos 2-4 do onboarding, revisitável
   a qualquer momento):
   - Acessibilidade: status + botão de correção. Três estados: "ativada",
     "pendente" (desligada) e "parada" — ligada nas configurações, mas o
     Android não está com o serviço conectado (o que ele mostra como
     "malfunctioning", p.ex. depois de o MIUI matar o app ao fechá-lo nos
     recentes). A verificação usa a lista de serviços conectados do
     `AccessibilityManager`, não só a configuração.
   - Otimização de bateria: status + botão de correção.
   - Autostart (MIUI): instruções + checkbox "Já fiz isso".

## 7. Armazenamento de dados

Tudo local, sem SQLite — `SharedPreferences` nativo é suficiente porque só
guardamos configurações e contadores do **dia corrente**, sem histórico. Se no
futuro for necessário histórico multi-dia, a implementação por trás do bridge
nativo pode mudar sem afetar as ViewModels — vantagem direta do Repository
Pattern (seção 3).

**Configurações:** Flutter chama `SettingsRepository.save(...)` → `MethodChannel`
→ Kotlin grava num `SharedPreferences` dedicado (chaves: `reels_block_enabled`,
`feed_limit_enabled`, `feed_limit_minutes`). O `AccessibilityService` lê essas
mesmas chaves diretamente (mesmo processo), mantendo um cache em memória
atualizado via `OnSharedPreferenceChangeListener` — evita releitura de disco a
cada evento de acessibilidade, que pode disparar com bastante frequência.

**Estatísticas:** o próprio `AccessibilityService` grava os contadores
diretamente no `SharedPreferences` — os de bloqueio no momento em que aciona
`GLOBAL_ACTION_HOME`, o tempo de Feed a cada intervalo fechado (troca de aba,
saída do Instagram, tela apagada) — chaves com a data embutida (ex:
`stats_reels_blocked_2026-09-26`, `stats_feed_millis_2026-09-26`,
`stats_feed_blocked_2026-09-26`),
evitando round-trip pelo Flutter pra registrar um evento que acontece com o app
em background. A tela Home lê via `StatsRepository.getToday()` →
`MethodChannel` → Kotlin retorna os números do dia atual (data local do
aparelho). O reset diário é "de graça": vira o dia, a chave muda. Chaves
antigas podem ser limpas por higiene (ex: descartar entradas com mais de 7
dias ao abrir o app) — não é requisito funcional, só limpeza.

**Status de permissões:** não é persistido — é sempre consultado ao vivo
(`AccessibilityManager`, `PowerManager.isIgnoringBatteryOptimizations()`), já
que pode mudar fora do controle do app. Exceção: o checkbox "Já fiz isso" do
Autostart no MIUI é persistido, pois é a única forma de saber — não existe API
para verificar isso de fato.

## 8. Tratamento de erros e casos-limite

- `getRootInActiveWindow()` pode retornar `null` esporadicamente (troca de
  janela em andamento) — o serviço simplesmente ignora o evento nesse caso,
  sem crashar.
- Se uma chamada de `MethodChannel` falhar (ex: engine Flutter ainda não
  pronta), o Repository propaga um erro tratável pela ViewModel, que exibe uma
  mensagem simples na tela — sem deixar o app em estado inconsistente.
- Se a Accessibility Service estiver desativada mas os toggles de
  Configurações continuarem "ligados", o app não finge que está protegendo: o
  card de status na Home mostra "⚠️ Ação necessária" (consulta ao vivo, ver
  seção 7).

## 9. Estratégia de testes

- **ViewModels (Dart):** testes unitários com repositórios fake (via overrides
  do Riverpod) — sem tocar em Android real.
- **Regras de detecção (Kotlin, Strategy Pattern):** testáveis isoladamente
  passando um `AccessibilityNodeInfo` fake/mockado para cada `DetectionRule`,
  sem precisar instanciar o serviço inteiro nem o Instagram de verdade.
- **Teste manual obrigatório no dispositivo real** para o fluxo fim-a-fim
  (abrir Instagram, entrar na aba Reels, rolar o Feed) — não dá pra automatizar
  isso de forma realista sem o Instagram instalado e um dispositivo físico.
- **Layout (Flutter):** cada tela roda numa matriz de celulares
  (`test/helpers/phone_viewport.dart`: 360×640 e 393×873 dp, fonte até 2,0×,
  navegação por gestos e por 3 botões, paisagem) e o teste falha se algum texto
  ficar sob as barras do sistema ou fora de alcance mesmo rolando.

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
560dp + conteúdo centralizado na vertical + ação fixa no rodapé), `GlassCard`, `TerminalLabel`, `StatusPill`,
`GradientText` e `StatValue`. Em `features/permissions/` fica o `PermissionCard`.

**Regra de responsividade:** toda tela é `AppScreen` + `ResponsiveBody`, e nenhum
conteúdo fica em `Column` de altura fixa sem scroll. O conteúdo fica centralizado na
vertical em todas as telas (o app mostra pouca coisa, e alinhado no topo a tela
parecia vazia); quando não cabe, começa no topo e rola. O app é edge-to-edge (o
Android desenha atrás das barras do sistema), então a área segura é obrigatória.
Foi a falta dela, junto com passos do onboarding que não rolavam, que fez as
explicações das permissões passarem da tela.
