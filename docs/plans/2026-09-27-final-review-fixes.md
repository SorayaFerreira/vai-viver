# Plano de correção — achados da revisão final de branch

> Contexto: depois das 18 tarefas do plano de implementação
> (`docs/plans/2026-09-26-vaiviver-mvp.md`) passarem individualmente na
> revisão, uma revisão final de todo o branch (modelo mais capaz, olhando
> só pra coisas que só aparecem na escala do app inteiro) encontrou 2 bugs
> críticos e vários problemas importantes que os testes unitários de cada
> tarefa não conseguiam pegar. Este documento é o plano de correção — tudo
> aqui entra numa **única rodada de correção** (o processo de execução não
> prevê uma segunda leva; por isso o escopo já inclui os itens importantes
> e alguns pequenos, não só os dois críticos).

## Críticos

### C1 — Limite de scroll nunca dispara (viewId sempre nulo)

**Arquivo:** `android/app/src/main/res/xml/accessibility_service_config.xml`

**Causa:** falta a flag `android:accessibilityFlags="flagReportViewIds"`. Sem
ela, o Android sempre retorna `null` em `getViewIdResourceName()` — e
`FeedScrollLimitRule` depende exclusivamente de viewId pra identificar a aba
Feed. Resultado: a regra nunca reconhece que você está no Feed, e o limite
de scroll nunca dispara.

**Correção:** adicionar `flagReportViewIds` (e `flagIncludeNotImportantViews`,
recomendado pelo revisor pra não perder nós que o Instagram marca como "não
importantes para acessibilidade" mas que ainda carregam o viewId).

### C2 — Regras detectam "o botão existe" em vez de "a aba está selecionada"

**Arquivos:** `ScreenNode.kt`, `ScreenNodeMapper.kt`, `ReelsTabRule.kt`,
`FeedScrollLimitRule.kt`, e os testes desses dois últimos.

**Causa:** a barra inferior do Instagram mostra os botões de todas as abas
(Feed, Buscar, Reels, Perfil) em **qualquer** tela do app — o botão "Reels"
está sempre presente na árvore, só não está selecionado quando você não
está nessa aba. `findFirst { contentDescription == "Reels" }` encontra esse
botão mesmo estando no Feed. Com o bloqueio de Reels ligado, isso levaria
você pra Home assim que abrisse o Instagram, em qualquer tela.

**Correção:**
- Adicionar um campo `isSelected: Boolean` em `ScreenNode`.
- `ScreenNodeMapper` passa a ler `AccessibilityNodeInfo.isSelected`.
- `ReelsTabRule` e `FeedScrollLimitRule` passam a exigir `isSelected == true`
  no nó encontrado, não só a presença do texto/id.
- Novos testes com uma árvore completa da barra inferior (todos os botões
  presentes), variando qual está selecionado, provando que a regra
  diferencia "existe" de "está selecionado".

## Importantes (mesma rodada)

- **I1 — Qualquer evento de outro app reseta a sessão de scroll.** Notificação,
  teclado aparecendo, painel de volume — tudo conta hoje como "saiu do
  Instagram". Correção: só `TYPE_WINDOW_STATE_CHANGED` pode encerrar a sessão.
- **I2 — O filtro de pacote olha o evento, não a janela realmente lida (gap
  no RF11).** Correção: verificar `rootNode.packageName` antes de processar,
  não só `event.packageName`.
- **I3 — Botão de isenção de bateria não faz nada.** Falta declarar
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` no manifest. Correção: uma linha.
- **I4 — Falha de canal deixa a tela girando pra sempre.** `refresh()`/updates
  das ViewModels não usam `AsyncValue.guard`. Correção: envolver as 3
  ViewModels + o `_finish()` do onboarding.
- **I5 — Onboarding não reage a permissão concedida nem trava o avanço.**
  Correção: mesmo observador de ciclo de vida que a Home já tem, e travar
  "Próximo" do passo de Acessibilidade até `accessibilityEnabled == true`.
- **I6 — 2 dos 5 itens de "Review Focus" do plano original não tinham teste
  de verdade.** Correção: adicionar os dois que dá pra cobrir sem uma
  refatoração maior — "sem acúmulo residual ao desativar/reativar o limite
  de scroll" e "a Home realmente re-consulta ao voltar do background".
- **I7 — docs/design.md desatualizado no branch.** As edições feitas durante
  a sessão (sobre o `packageNames` e o risco de contagem duplicada) nunca
  foram commitadas. Vou commitar isso eu mesma, fora da rodada de correção
  do subagente, já que é conteúdo que você já revisou comigo.
- **I8 — Risco de contagem duplicada nas estatísticas** (já registrado como
  risco conhecido na seção 4.2 do design, mas o revisor confirmou que vale
  corrigir agora, não só anotar). Correção: o serviço continua indo pra Home
  a cada evento correspondente (inofensivo), mas só incrementa as
  estatísticas uma vez por sessão.

## Pequenos (mesmo lote, baratos)

- `dart format lib test` (só formatação)
- `dispose()` do `PageController` no onboarding
- Assertiva faltando no teste do onboarding (`setOnboardingCompleteCallCount`)
- Remover o parâmetro `statsStore` não utilizado do `FeedScrollLimitRule`
- Corrigir `android:label="vaiviver"` → `"VaiViver"`

## Fora desta rodada (registrados, não bloqueiam)

- Duas chamadas de repositório direto sem passar pela ViewModel (pequeno
  vazamento de MVVM)
- `NativeBridge()` instanciado separadamente em cada ViewModel em vez de um
  único provider central
- Corrida de clique duplo no stepper de minutos
- Descrição do design.md sobre um listener de cache que não foi
  implementado literalmente (equivalente na prática)
- Pastas de scaffold não usadas (ios/macos/linux/windows/web)
- Strings nativas do Material (tooltips padrão etc.) não localizadas

## Próximos passos

1. Disparar **um único** subagente de correção com toda essa lista.
2. Uma revisão focada (escopo restrito a essa rodada, não uma revisão
   completa nova).
3. Eu commito as edições do design.md separadamente.
4. Se limpo: fechamento da branch (`finishing-a-development-branch`).
