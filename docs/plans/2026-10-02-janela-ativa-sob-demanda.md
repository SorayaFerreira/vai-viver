# Janela ativa consultada só quando precisa — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parar de consultar a janela ativa (`rootInActiveWindow`) a cada evento
de outros apps. A consulta passa a acontecer só quando o evento pode de fato
encerrar a sessão, sem mudar nenhum comportamento do app.

**Architecture:** `isLeavingInstagram` passa a receber a janela ativa como função
(`() -> String?`) em vez de valor já calculado. Como ela é o último operando da
cadeia de `&&`, só é chamada quando os três testes baratos (pacote não nulo,
pacote diferente do Instagram, evento `TYPE_WINDOW_STATE_CHANGED`) já passaram.
O serviço passa `::activeWindowPackage` no lugar de `activeWindowPackage()`.

**Tech Stack:** Kotlin (AccessibilityService, JUnit 4).

**Spec:** a seção "Análise" abaixo, feita na conversa de 2026-10-02.

## Análise

### O problema

Em `VaiViverAccessibilityService.onAccessibilityEvent`, o Kotlin avalia
`activeWindowPackage()` **antes** de chamar `isLeavingInstagram`, porque é um
argumento. O curto-circuito do `&&` dentro da função não ajuda, já que o valor
chega pronto. O serviço não tem filtro `android:packageNames` (decisão de
design, ver design.md §4.1), então recebe `TYPE_WINDOW_CONTENT_CHANGED` de
qualquer app, até ~10 por segundo (`notificationTimeout="100"`). Cada um desses
eventos dispara uma chamada entre processos ao app em primeiro plano, e o
resultado é descartado.

### Equivalência (por que nada muda no comportamento)

| Evento que chega ao `else if` | Hoje lê a janela ativa? | Depois | Resultado de `isLeavingInstagram` |
|---|---|---|---|
| Pacote nulo | sim | não | `false` nos dois casos |
| Outro pacote, `CONTENT_CHANGED` | sim | não | `false` nos dois casos |
| Outro pacote, `STATE_CHANGED` | sim, 1× | sim, 1× | o mesmo (depende da janela ativa) |
| Instagram | não chega aqui (vai para `checkInstagramWindow`) | idem | — |

`endSession()` continua sendo chamado exatamente nas mesmas situações.

### Efeitos colaterais da chamada removida

- **Chamada entre processos:** é o custo que queremos cortar.
- **`recycle()`:** não faz nada no Android 13+ (RNF01).
- **Cache de nós do framework:** `getRootInActiveWindow()` pré-carrega
  descendentes da janela ativa no cache de acessibilidade do serviço. As leituras
  removidas só alimentavam esse cache por acaso, quando um evento de outro pacote
  (teclado, System UI) chegava no meio do uso do Instagram. O caminho principal
  (rolar o Feed, que gera eventos quase só do Instagram) já funciona hoje sem
  essas leituras, e o framework mantém o cache coerente pelos próprios eventos.
  Não há perda de correção, só de pré-carga incidental.
- **Exceções:** `rootInActiveWindow` devolve `null` em vez de lançar; menos
  chamadas não criam caminho de erro novo.

### Ganho extra (RF11)

Como a pré-carga de `getRootInActiveWindow()` traz nós do app que estiver na
frente, hoje o serviço puxa para a memória um pedaço da árvore de **outros apps**
a cada evento de conteúdo deles (nunca lido pelo nosso código, nunca gravado).
Depois da mudança isso só acontece em trocas de janela, bem mais raras.

### Por que uma função como parâmetro (e não um `if` no serviço)

- A regra "só lê a janela quando precisa" vira contrato de `isLeavingInstagram`,
  testável em JUnit puro. O serviço não tem testes unitários.
- Não duplica no serviço a checagem de tipo de evento que já existe na função.
- Segue o idioma do projeto: `FeedTimeTracker` recebe `clock: () -> Long`.
- A referência `::activeWindowPackage` aloca um objeto pequeno por evento. Isso é
  desprezível perto da chamada entre processos que ela evita; não vale um
  `inline`.

## Global Constraints

- **Nunca rodar `git commit`, em hipótese alguma** (CLAUDE.md). A tarefa termina
  no working tree, para a autora revisar e commitar.
- Testes Kotlin: `cd android && ./gradlew testDebugUnitTest -q` (≈1 min). Esse
  comando também compila o código de `main`, então pega erro de compilação no
  serviço. Resultados em `build/app/test-results/testDebugUnitTest/*.xml`.
- Linha de base em 2026-10-02: suíte Kotlin verde, `SessionBoundaryTest` 4/4.
- Comentários de código em inglês; textos de docs em pt-BR.
- Nenhuma mudança no lado Flutter, no manifest ou em
  `accessibility_service_config.xml`.
- RF11: conteúdo de tela só é lido quando a janela ativa é do Instagram.

## Review Focus

1. **Teclado, volume ou notificação por cima do Instagram** (`STATE_CHANGED` de
   outro pacote com o Instagram ainda ativo): não pode encerrar a sessão. A janela
   ativa precisa continuar sendo lida nesse caso. Teste existente "a dialog from
   another package…", mantido na Tarefa 1.
2. **Troca real para outro app:** encerra a sessão, lendo a janela ativa uma vez
   só. Teste existente "another app taking…" + teste novo "reads the active
   window once" na Tarefa 1.
3. **Eventos de conteúdo de outros apps** (WhatsApp atualizando em segundo plano,
   digitação no teclado): não leem a janela ativa. Teste novo "don't read the
   active window" na Tarefa 1.
4. **Evento sem pacote:** não lê a janela ativa. Mesmo teste novo.
5. **Alguém reordenar a cadeia de `&&` no futuro** e colocar a leitura antes dos
   testes baratos: o teste novo do item 3 precisa falhar. Verificado de propósito
   no Step 5 da Tarefa 1.

## Mapa de arquivos

| Arquivo | Mudança |
|---|---|
| `android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/SessionBoundary.kt` | Parâmetro `activeWindowPackage` vira `() -> String?`; KDoc explica o porquê |
| `android/app/src/main/kotlin/com/sorayaferreira/vaiviver/VaiViverAccessibilityService.kt:64` | Passa `::activeWindowPackage` |
| `android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/SessionBoundaryTest.kt` | Testes existentes adaptados + 2 testes de leitura sob demanda |
| `docs/design.md` §4.1 | Uma frase registrando quando a janela ativa é consultada |

## Fora de escopo (ideias para depois, não fazer aqui)

- Usar `getRootInActiveWindow(0)` (API 33+, sem pré-carga) dentro de
  `activeWindowPackage()`: as leituras que sobram trariam só o nó raiz, mais
  baratas e sem nenhum nó de outros apps. Pede checagem de versão, porque o
  `minSdk` do Flutter é menor que 33.
- Pedir `TYPE_WINDOW_CONTENT_CHANGED` só enquanto o Instagram está na frente
  (`setServiceInfo()` em tempo de execução). Reduz eventos gerados por todos os
  apps, mas mexe na entrega de eventos e exige teste longo no aparelho.

---

### Task 1: Leitura da janela ativa sob demanda

**Files:**
- Modify: `android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/SessionBoundary.kt` (arquivo inteiro, 19 linhas)
- Modify: `android/app/src/main/kotlin/com/sorayaferreira/vaiviver/VaiViverAccessibilityService.kt:64`
- Modify: `docs/design.md:105-106` (fim do primeiro item de §4.1)
- Test: `android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/SessionBoundaryTest.kt`

**Interfaces:**
- Consumes: `const val INSTAGRAM_PACKAGE` (mesmo arquivo); no serviço,
  `private fun activeWindowPackage(): String?` (já existe, não muda).
- Produces:
  `fun isLeavingInstagram(eventPackage: String?, eventType: Int, activeWindowPackage: () -> String?): Boolean`.
  Único chamador: `VaiViverAccessibilityService.onAccessibilityEvent`.

- [ ] **Step 1: Escrever os testes (que falham)**

Substituir `SessionBoundaryTest.kt` inteiro. Os quatro testes antigos ficam com a
mesma intenção, agora passando a janela como lambda final. Os dois novos contam
quantas vezes a janela foi lida.

```kotlin
package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionBoundaryTest {
    @Test
    fun `another app taking the active window ends the session`() {
        assertTrue(isLeavingInstagram("com.miui.home", TYPE_WINDOW_STATE_CHANGED) { "com.miui.home" })
    }

    @Test
    fun `a dialog from another package over Instagram does not (keyboard, volume, notification)`() {
        assertFalse(isLeavingInstagram("com.android.systemui", TYPE_WINDOW_STATE_CHANGED) { INSTAGRAM_PACKAGE })
    }

    @Test
    fun `non window-state events from other packages are ignored`() {
        assertFalse(isLeavingInstagram("com.whatsapp", TYPE_WINDOW_CONTENT_CHANGED) { "com.whatsapp" })
    }

    @Test
    fun `events without a package are ignored`() {
        assertFalse(isLeavingInstagram(null, TYPE_WINDOW_STATE_CHANGED) { null })
    }

    @Test
    fun `events that can't end the session don't read the active window`() {
        var reads = 0
        val activeWindow = { reads++; "com.whatsapp" }

        isLeavingInstagram("com.whatsapp", TYPE_WINDOW_CONTENT_CHANGED, activeWindow)
        isLeavingInstagram(null, TYPE_WINDOW_STATE_CHANGED, activeWindow)
        isLeavingInstagram(INSTAGRAM_PACKAGE, TYPE_WINDOW_STATE_CHANGED, activeWindow)

        assertEquals(0, reads)
    }

    @Test
    fun `a window-state event from another package reads the active window once`() {
        var reads = 0

        isLeavingInstagram("com.miui.home", TYPE_WINDOW_STATE_CHANGED) { reads++; "com.miui.home" }

        assertEquals(1, reads)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd android && ./gradlew testDebugUnitTest -q`
Expected: FAIL de compilação em `SessionBoundaryTest.kt`, algo como
"Argument type mismatch: actual type is '() -> String', but 'String?' was
expected". A assinatura atual ainda recebe `String?`.

- [ ] **Step 3: Implementar a mudança**

`SessionBoundary.kt` completo:

```kotlin
package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent

const val INSTAGRAM_PACKAGE = "com.instagram.android"

/**
 * Whether an event from another package means the user really left Instagram.
 * The keyboard, the volume panel and notifications are dialogs owned by other
 * packages and also emit TYPE_WINDOW_STATE_CHANGED, so the event alone isn't
 * enough: the active window must no longer be Instagram's. Only package names
 * are compared — no other app's content is read.
 *
 * [activeWindowPackage] is called only when the event itself can't settle it:
 * reading the active window is a call into the foreground app, and content
 * changes from every app reach the service several times a second.
 */
fun isLeavingInstagram(eventPackage: String?, eventType: Int, activeWindowPackage: () -> String?): Boolean =
    eventPackage != null &&
        eventPackage != INSTAGRAM_PACKAGE &&
        eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
        activeWindowPackage() != INSTAGRAM_PACKAGE
```

A leitura **tem** de ser o último operando: é isso que os testes novos garantem.

Em `VaiViverAccessibilityService.kt`, linha 64, trocar:

```kotlin
        } else if (isLeavingInstagram(eventPackage, event.eventType, activeWindowPackage())) {
```

por:

```kotlin
        } else if (isLeavingInstagram(eventPackage, event.eventType, ::activeWindowPackage)) {
```

Nada mais muda no serviço. `activeWindowPackage()` continua igual e continua
sendo o único lugar que lê a janela ativa fora de `checkInstagramWindow`.

- [ ] **Step 4: Rodar e ver passar**

Run: `cd android && ./gradlew testDebugUnitTest -q`
Expected: exit 0, sem saída além dos avisos `WARNING: A restricted method…` do
Gradle (são normais). Conferir a contagem, a partir da raiz do repositório:

```bash
grep -o 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*" errors="[0-9]*"' \
  build/app/test-results/testDebugUnitTest/TEST-com.sorayaferreira.vaiviver.detection.SessionBoundaryTest.xml
```

Expected: `tests="6" skipped="0" failures="0" errors="0"`.

- [ ] **Step 5: Provar que o teste de leitura pega uma regressão**

Mutação temporária: em `SessionBoundary.kt`, mover a leitura para o começo da
cadeia:

```kotlin
    activeWindowPackage() != INSTAGRAM_PACKAGE &&
        eventPackage != null &&
        eventPackage != INSTAGRAM_PACKAGE &&
        eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
```

Run: `cd android && ./gradlew testDebugUnitTest -q`
Expected: FAIL em `events that can't end the session don't read the active window`
com `expected:<0> but was:<3>`. Os outros 5 continuam passando.

Depois **desfazer** a mutação (voltar ao código do Step 3) e rodar de novo:
Expected: exit 0, `tests="6" … failures="0"`.

- [ ] **Step 6: Registrar no design.md**

Em `docs/design.md`, §4.1, o primeiro item termina com:

```markdown
  `com.instagram.android` — para qualquer outro app, o evento é usado só para
  comparar o nome do pacote e descartado em seguida, nunca lido a fundo.
```

Acrescentar quatro linhas logo depois, no mesmo item. O trecho fica assim:

```markdown
  `com.instagram.android` — para qualquer outro app, o evento é usado só para
  comparar o nome do pacote e descartado em seguida, nunca lido a fundo.
  A janela ativa (`rootInActiveWindow`, uma chamada ao app em primeiro plano)
  só é consultada quando chega um `TYPE_WINDOW_STATE_CHANGED` de outro pacote;
  os `TYPE_WINDOW_CONTENT_CHANGED` de outros apps, que chegam várias vezes por
  segundo, são descartados pelo tipo, sem consulta (2026-10-02).
```

- [ ] **Step 7: Deixar no working tree (sem commit)**

```bash
git status --short
```

Expected: exatamente estes 4 arquivos modificados, nenhum outro:

```
 M android/app/src/main/kotlin/com/sorayaferreira/vaiviver/VaiViverAccessibilityService.kt
 M android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/SessionBoundary.kt
 M android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/SessionBoundaryTest.kt
 M docs/design.md
```

(Mais este plano, se ainda não tiver sido commitado.) **Não rodar `git commit`.**
Avisar a autora que está pronto para revisão.

---

### Task 2: Conferência no aparelho (feita pela autora)

O serviço não tem teste unitário, então a ligação `::activeWindowPackage` só é
exercitada de verdade no celular. Isto é uma conferência rápida de que nada
mudou, não uma medição de bateria: o ganho é pequeno demais para aparecer na
tela de bateria do Android em poucas horas.

- [ ] **Step 1: Instalar o build novo**

Com o celular conectado por USB (depuração ativada):

```bash
.fvm/flutter_sdk/bin/flutter run --release
```

Abrir o VaiViver depois de instalar e conferir na Home que a Acessibilidade
continua **ativada**. No MIUI/HyperOS uma reinstalação pode desligá-la (ver item
14 do checklist).

- [ ] **Step 2: Rodar os itens de `docs/manual-test-checklist.md` que dependem do fim de sessão**

- **Item 18:** na Início, abrir o teclado, apertar o volume e puxar uma
  notificação: nada disso encerra a sessão. Depois do limite, voltar à Início
  expulsa na hora, sem nova janela de 5 s.
- **Item 12:** com o limite estourado, sair do Instagram (botão Home) e reabrir:
  a janela de ~5 s aparece de novo. Isso prova que a saída real ainda é
  detectada.
- **Item 17:** tocar na aba Reels 3 vezes, reabrindo o Instagram entre um toque
  e outro (o bloqueio te leva para fora): o contador sobe um por toque.

Expected: os três itens se comportam exatamente como antes da mudança.
