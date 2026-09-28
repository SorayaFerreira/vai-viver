# Limite diário de tempo no Feed — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar o "limite de scroll por sessão" (que não funcionou no aparelho)
por um **limite diário de tempo com a aba Início do Instagram aberta**, padrão de
20 minutos.

**Architecture:** No lado nativo, `HomeTabDetector` diz se a aba Início está
selecionada. `FeedTimeTracker` soma os intervalos em que ela esteve na tela e grava
o total do dia. `FeedTimeLimitRule` (Strategy, como as outras regras) bloqueia ao
estourar o limite, com uma janela de 5 s na abertura do Instagram. O serviço
reaproveita os eventos que já recebe e acrescenta um timer de prazo (para quando
você fica parada no Feed) e o aviso de tela desligada. No Flutter, só mudam os
nomes, os campos e os textos: configurações, estatísticas e o card da Home.

**Tech Stack:** Kotlin (AccessibilityService, JUnit 4), Flutter 3.47.5 (FVM), Riverpod 3.

**Spec:** a seção "Decisões de design" abaixo, acordada na conversa de
2026-09-28. A Tarefa 8 a registra em `docs/design.md` e `docs/requirements.md`.

## Decisões de design

- **O que conta:** todo o tempo com a aba **Início** selecionada na barra inferior
  (a lista do Feed e perfis, posts e comentários abertos a partir dela). Stories em
  tela cheia não contam, porque a barra some. Rolar ou ficar parada conta igual.
- **Reset:** **diário**, à meia-noite, no fuso do aparelho. Sair e voltar ao
  Instagram não zera nada.
- **Limite:** padrão de **20 min/dia**, configurável. O stepper vai de 1 em 1 até
  5 min e de 5 em 5 a partir daí.
- **Ao estourar:** `GLOBAL_ACTION_HOME`, como antes.
- **Janela de 5 s:** com o limite já estourado, ao **abrir** o Instagram, que sempre
  começa na Início, você tem 5 s para tocar em DM, Buscar ou Perfil. Voltar para a
  Início no meio da sessão expulsa na hora.
- **Medição (abordagem A):** intervalos marcados pelos eventos que o serviço já
  recebe, mais um timer agendado para o instante do limite (relê a tela uma vez e
  confere se você ainda está na Início), mais `ACTION_SCREEN_OFF` para não contar
  tempo com a tela apagada. Não há checagem periódica.
- **Substituição:** a regra de scroll sai inteira (`FeedScrollLimitRule`,
  `ScrollActivityAccumulator`, `BlockReason.SCROLL_LIMIT`, as chaves
  `scroll_limit_*` e as estatísticas de scroll).
- **Estatísticas do dia:** Reels bloqueados, tempo de Feed usado e saídas forçadas
  do Feed.
- **Diagnóstico primeiro:** um log que só existe em build de debug registra os nós
  *selecionados* da tela do Instagram (`viewId`, `contentDescription` e classe,
  nunca o conteúdo de posts). A calibração da aba Início usa esse log (Tarefa 9).

## Por que o scroll provavelmente falhou

A `FeedScrollLimitRule` reconhecia o Feed **só** por `viewId` contendo
`feed_tab`/`home_tab` num nó selecionado, sem alternativa. A `ReelsTabRule`, que
funcionou, também aceita `contentDescription == "Reels"`. Se os `viewId`s chutados
não batem com a versão instalada do Instagram, o Feed nunca é reconhecido, e a regra
nova herdaria o mesmo defeito. Por isso a Tarefa 1 é o log de diagnóstico, e o
`HomeTabDetector` aceita também o nome acessível do botão.

## Global Constraints

- **Nunca rodar `git commit`, em hipótese alguma** (CLAUDE.md). As tarefas
  terminam no working tree.
- Flutter/Dart via `.fvm/flutter_sdk/bin/…`. Testes Kotlin:
  `cd android && ./gradlew testDebugUnitTest -q`. Os resultados ficam em
  `build/app/test-results/testDebugUnitTest/*.xml`.
- Fontes: `tool/fetch_fonts.sh` já foi rodado neste clone.
- RF11: o conteúdo da tela só é lido quando a janela ativa é do Instagram. O log de
  diagnóstico só existe em build debuggable e só registra nós selecionados.
- Texto de UI em pt-BR. Comentários de código em inglês.
- Fim de cada tarefa: testes Kotlin verdes, `dart format lib test`,
  `flutter analyze` sem issues e `flutter test` verde.

## Review Focus

1. **Parada no Feed sem tocar em nada:** o bloqueio precisa vir do timer de prazo,
   porque não chegam eventos. Coberto por `millisUntilNextCheck` (Tarefa 5). O
   disparo real só é verificável no aparelho (item do checklist, Tarefa 8).
2. **Tela apagada com o Instagram na Início:** não pode contar tempo. Coberto pelo
   `stop()` do tracker (Tarefa 4), acionado por `ACTION_SCREEN_OFF` (Tarefa 6).
3. **Virada da meia-noite com a Início aberta:** conta só a partir das 00:00 do dia
   novo (teste na Tarefa 4).
4. **Notificação, volume ou teclado durante o Feed:** não podem encerrar a sessão (o
   que daria 5 s de graça de novo). Coberto por `isLeavingInstagram` (Tarefa 6).
5. **Limite desligado:** o tempo continua sendo contado (a Home mostra), mas nunca
   bloqueia. Coberto na Tarefa 5.

## Mapa de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `android/.../detection/TabDiagnostics.kt` (novo) | Resume os nós selecionados para o log de debug |
| `android/.../detection/HomeTabDetector.kt` (novo) | "A aba Início está selecionada?" |
| `android/.../detection/FeedTimeTracker.kt` (novo) | Soma os intervalos na Início e grava o total do dia |
| `android/.../detection/FeedTimeLimitRule.kt` (novo) | Regra: limite diário + janela de 5 s + prazo do próximo check |
| `android/.../detection/SessionBoundary.kt` (novo) | `isLeavingInstagram(...)`, `INSTAGRAM_PACKAGE` |
| `android/.../detection/FeedScrollLimitRule.kt`, `ScrollActivityAccumulator.kt` (+ testes) | **removidos** |
| `android/.../data/{AppSettings,SettingsStore,DailyStats,StatsStore,NativeBridge}.kt` | Campos e chaves novos |
| `android/.../VaiViverAccessibilityService.kt` | Timer de prazo, tela desligada, fim de sessão confiável, log |
| `lib/domain/models/{app_settings,daily_stats}.dart`, `lib/domain/feed_limit_steps.dart` (novo) | Modelos e passos do stepper |
| `lib/data/method_channel_*_repository.dart`, `lib/features/settings/*`, `lib/features/home/home_screen.dart` | Campos, textos e card da Home |
| `docs/*` | Requisitos, design e checklist |

(`android/...` = `android/app/src/main/kotlin/com/sorayaferreira/vaiviver`. Os
testes ficam no espelho `android/app/src/test/kotlin/...`.)

---

### Task 1: Log de diagnóstico dos nós selecionados

**Files:**
- Create: `android/.../detection/TabDiagnostics.kt`
- Modify: `android/.../VaiViverAccessibilityService.kt`
- Test: `android/app/src/test/.../detection/TabDiagnosticsTest.kt`

**Interfaces:**
- Produces: `fun describeSelectedNodes(root: ScreenNode): List<String>`, em que
  cada item é `"viewId=<id> desc=<desc> class=<class>"`, na ordem de pré-ordem.

- [ ] **Step 1: Teste que falha**

```kotlin
package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Test

class TabDiagnosticsTest {
    @Test
    fun `lists only selected nodes, in tree order, with their identifiers`() {
        val root = ScreenNode(
            viewId = "root", contentDescription = null, className = "FrameLayout",
            children = listOf(
                ScreenNode("com.instagram.android:id/feed_tab", "Página inicial", "FrameLayout", isSelected = true),
                ScreenNode("com.instagram.android:id/clips_tab", "Reels", "FrameLayout"),
                ScreenNode(null, null, "ImageView", isSelected = true)
            )
        )

        assertEquals(
            listOf(
                "viewId=com.instagram.android:id/feed_tab desc=Página inicial class=FrameLayout",
                "viewId=null desc=null class=ImageView"
            ),
            describeSelectedNodes(root)
        )
    }
}
```

Run: `cd android && ./gradlew testDebugUnitTest -q`
Expected: FAIL de compilação (`describeSelectedNodes` não existe).

- [ ] **Step 2: Implementar**

`TabDiagnostics.kt`:

```kotlin
package com.sorayaferreira.vaiviver.detection

/**
 * Debug aid for calibrating tab detection: the identifiers of every selected
 * node on screen (the active bottom-nav tab is one of them). Identifiers only —
 * never the text of posts.
 */
fun describeSelectedNodes(root: ScreenNode): List<String> {
    val out = mutableListOf<String>()
    fun visit(node: ScreenNode) {
        if (node.isSelected) {
            out += "viewId=${node.viewId} desc=${node.contentDescription} class=${node.className}"
        }
        node.children.forEach(::visit)
    }
    visit(root)
    return out
}
```

No serviço, acrescente os imports `android.content.pm.ApplicationInfo`,
`android.util.Log` e `detection.describeSelectedNodes`, o campo
`private var lastTabLog: List<String>? = null` e, logo depois de montar
`screenNode` (antes de `evaluateRules`), a chamada `logSelectedTabs(screenNode)`,
com:

```kotlin
    /** Debug builds only: logs the selected nodes whenever they change. */
    private fun logSelectedTabs(screen: ScreenNode) {
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        val summary = describeSelectedNodes(screen)
        if (summary != lastTabLog) {
            lastTabLog = summary
            Log.d(TAG, "selected: $summary")
        }
    }
```

e `private const val TAG = "VaiViver/tabs"` no `companion object` (importe `ScreenNode`).

- [ ] **Step 3: Verde + build**

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: todos passam.
Run: `.fvm/flutter_sdk/bin/flutter build apk --debug` → Expected: APK gerado.

- [ ] **Step 4: Pedir o log à Soraya (não bloqueia as próximas tarefas)**

Instruções para ela: `.fvm/flutter_sdk/bin/flutter run` com o celular conectado,
abrir o Instagram, tocar na aba **Início**, depois em **Reels**, depois em
**Perfil**, e colar as linhas `VaiViver/tabs` (ou rodar
`adb logcat -s VaiViver/tabs`). A Tarefa 9 usa essas linhas.

---

### Task 2: `HomeTabDetector`

**Files:**
- Create: `android/.../detection/HomeTabDetector.kt`
- Test: `android/app/src/test/.../detection/HomeTabDetectorTest.kt`

**Interfaces:**
- Produces: `object HomeTabDetector { fun isHomeTabSelected(root: ScreenNode): Boolean; val VIEW_ID_KEYWORDS: List<String>; val CONTENT_DESCRIPTIONS: List<String> }`

- [ ] **Step 1: Testes que falham**

```kotlin
package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HomeTabDetectorTest {
    private fun bottomNav(home: ScreenNode, reelsSelected: Boolean = false) = ScreenNode(
        viewId = "root", contentDescription = null, className = "FrameLayout",
        children = listOf(
            home,
            ScreenNode("clips_tab", "Reels", "FrameLayout", isSelected = reelsSelected)
        )
    )

    @Test
    fun `selected button with a known view id is the home tab`() {
        assertTrue(HomeTabDetector.isHomeTabSelected(
            bottomNav(ScreenNode("com.instagram.android:id/feed_tab", null, "FrameLayout", isSelected = true))
        ))
    }

    @Test
    fun `selected button with a known accessible name is the home tab, whatever its id`() {
        assertTrue(HomeTabDetector.isHomeTabSelected(
            bottomNav(ScreenNode("tab_0", "Página inicial", "FrameLayout", isSelected = true))
        ))
    }

    @Test
    fun `home button present but not selected is not the home tab`() {
        assertFalse(HomeTabDetector.isHomeTabSelected(
            bottomNav(ScreenNode("feed_tab", "Página inicial", "FrameLayout"), reelsSelected = true)
        ))
    }
}
```

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: FAIL de compilação.

- [ ] **Step 2: Implementar**

```kotlin
package com.sorayaferreira.vaiviver.detection

/**
 * Tells whether Instagram's Home (Início) tab is the selected one. The bottom
 * nav renders every tab's button on every screen; only the active one is
 * selected, and the marker must be on that node itself. Matches by view id or
 * by accessible name, like ReelsTabRule, so one wrong guess doesn't blind it.
 */
object HomeTabDetector {
    // Calibrated against the installed Instagram in Task 9 (logs from Task 1).
    val VIEW_ID_KEYWORDS = listOf("feed_tab", "home_tab")
    val CONTENT_DESCRIPTIONS = listOf("Página inicial", "Início", "Home")

    fun isHomeTabSelected(root: ScreenNode): Boolean = root.findFirst { node ->
        node.isSelected && (
            VIEW_ID_KEYWORDS.any { node.viewId?.contains(it, ignoreCase = true) == true } ||
                CONTENT_DESCRIPTIONS.any { node.contentDescription?.equals(it, ignoreCase = true) == true }
            )
    } != null
}
```

- [ ] **Step 3: Verde**

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: todos passam.

---

### Task 3: Dados nativos — configurações e estatísticas novas; remover a regra de scroll

**Files:**
- Modify: `android/.../data/AppSettings.kt`, `SettingsStore.kt`, `DailyStats.kt`,
  `StatsStore.kt`, `NativeBridge.kt`, `android/.../detection/BlockReason.kt`,
  `android/.../VaiViverAccessibilityService.kt`
- Delete: `detection/FeedScrollLimitRule.kt`, `detection/ScrollActivityAccumulator.kt`
  e os testes `FeedScrollLimitRuleTest.kt` e `ScrollActivityAccumulatorTest.kt`
- Test: `data/SettingsStoreTest.kt`, `data/StatsStoreTest.kt`, `data/NativeBridgeTest.kt`

**Interfaces:**
- Produces:
  - `AppSettings(reelsBlockEnabled: Boolean, feedLimitEnabled: Boolean, feedLimitMinutes: Int)`;
    `DEFAULT = (true, true, 20)`. Chaves: `feed_limit_enabled`, `feed_limit_minutes`.
  - `DailyStats(reelsBlockedCount: Int, feedSecondsToday: Int, feedBlockedCount: Int)`;
    `EMPTY` com zeros.
  - `StatsStore.addFeedMillis(millis: Long)`, `StatsStore.feedMillisToday(): Long`,
    `StatsStore.incrementFeedBlocked()`. Chaves: `stats_feed_millis_<data>`,
    `stats_feed_blocked_<data>`.
  - `BlockReason { REELS_TAB, FEED_TIME_LIMIT }`.
  - Bridge: `getSettings`/`setSettings` usam `feedLimitEnabled`/`feedLimitMinutes`;
    `getTodayStats` devolve `reelsBlockedCount`, `feedSecondsToday` e `feedBlockedCount`.

- [ ] **Step 1: Atualizar os testes (vermelho)**

- `SettingsStoreTest`: em `round-trips saved settings`, use
  `AppSettings(reelsBlockEnabled = false, feedLimitEnabled = true, feedLimitMinutes = 25)`
  e acrescente:

```kotlin
    @Test
    fun `default daily feed limit is 20 minutes`() {
        assertEquals(20, SettingsStore(InMemoryKeyValueStore()).getSettings().feedLimitMinutes)
    }
```

- `StatsStoreTest`: troque o segundo teste por:

```kotlin
    @Test
    fun `accumulates reels blocks, feed time and feed blocks for the same day`() {
        val store = StatsStore(InMemoryKeyValueStore(), today = { "2026-09-26" })

        store.incrementReelsBlocked()
        store.incrementReelsBlocked()
        store.addFeedMillis(90_500)
        store.addFeedMillis(30_000)
        store.incrementFeedBlocked()

        assertEquals(120_500L, store.feedMillisToday())
        assertEquals(DailyStats(reelsBlockedCount = 2, feedSecondsToday = 120, feedBlockedCount = 1), store.getToday())
    }
```

  E, em `keeps separate counters per day`, depois de trocar a data, acrescente
  também `store.addFeedMillis(1_000)` antes da troca e
  `assertEquals(0L, store.feedMillisToday())` depois dela.
- `NativeBridgeTest`: em `getSettings…`, `copy(feedLimitMinutes = 25)` e
  `assertEquals(25, map["feedLimitMinutes"])`. Em `setSettings…`, os args passam a
  ser `"feedLimitEnabled" to true, "feedLimitMinutes" to 30`, com
  `assertEquals(30, settingsStore.getSettings().feedLimitMinutes)`. Acrescente:

```kotlin
    @Test
    fun `getTodayStats exposes feed time in seconds and feed blocks`() {
        val stats = StatsStore(InMemoryKeyValueStore()).apply {
            addFeedMillis(61_900)
            incrementFeedBlocked()
        }
        val result = RecordingResult()

        bridge(statsStore = stats).onMethodCall(MethodCall("getTodayStats", null), result)

        val map = result.success as Map<*, *>
        assertEquals(61, map["feedSecondsToday"])
        assertEquals(1, map["feedBlockedCount"])
        assertEquals(0, map["reelsBlockedCount"])
    }
```

- Apague `FeedScrollLimitRuleTest.kt` e `ScrollActivityAccumulatorTest.kt`.

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: FAIL de compilação.

- [ ] **Step 2: Implementar**

`AppSettings.kt`:

```kotlin
data class AppSettings(
    val reelsBlockEnabled: Boolean,
    val feedLimitEnabled: Boolean,
    val feedLimitMinutes: Int
) {
    companion object {
        val DEFAULT = AppSettings(
            reelsBlockEnabled = true,
            feedLimitEnabled = true,
            feedLimitMinutes = 20
        )
    }
}
```

`SettingsStore.kt`: troque os campos e as chaves por `feed_limit_enabled` e
`feed_limit_minutes` (constantes `KEY_FEED_LIMIT_ENABLED` e
`KEY_FEED_LIMIT_MINUTES`). As chaves antigas `scroll_limit_*` ficam órfãs no
SharedPreferences e são ignoradas.

`DailyStats.kt`:

```kotlin
data class DailyStats(
    val reelsBlockedCount: Int,
    val feedSecondsToday: Int,
    val feedBlockedCount: Int
) {
    companion object {
        val EMPTY = DailyStats(reelsBlockedCount = 0, feedSecondsToday = 0, feedBlockedCount = 0)
    }
}
```

`StatsStore.kt`: remova `addScrollSecondsSaved` e `scrollSecondsKey` e acrescente:

```kotlin
    fun addFeedMillis(millis: Long) {
        val key = feedMillisKey(today())
        store.putInt(key, (store.getInt(key, 0) + millis).toInt())
    }

    fun feedMillisToday(): Long = store.getInt(feedMillisKey(today()), 0).toLong()

    fun incrementFeedBlocked() {
        val key = feedBlockedKey(today())
        store.putInt(key, store.getInt(key, 0) + 1)
    }
```

O `getToday()` passa a ser:

```kotlin
    fun getToday(): DailyStats {
        val date = today()
        return DailyStats(
            reelsBlockedCount = store.getInt(reelsBlockedKey(date), 0),
            feedSecondsToday = store.getInt(feedMillisKey(date), 0) / 1000,
            feedBlockedCount = store.getInt(feedBlockedKey(date), 0)
        )
    }
```

com as chaves `stats_feed_millis_$date` e `stats_feed_blocked_$date`. Um dia inteiro
tem 86,4 milhões de ms, bem abaixo do máximo de um `Int`.

`BlockReason.kt`: `enum class BlockReason { REELS_TAB, FEED_TIME_LIMIT }`.

`NativeBridge.kt`: troque as chaves de `getSettings`/`setSettings` para
`feedLimitEnabled`/`feedLimitMinutes`, e o `getTodayStats` para:

```kotlin
                        "reelsBlockedCount" to stats.reelsBlockedCount,
                        "feedSecondsToday" to stats.feedSecondsToday,
                        "feedBlockedCount" to stats.feedBlockedCount
```

Serviço (estado intermediário, que a Tarefa 6 completa): `rules = listOf(ReelsTabRule(settingsStore))`,
remova o import de `FeedScrollLimitRule` e troque o ramo `SCROLL_LIMIT` por
`BlockReason.FEED_TIME_LIMIT -> statsStore.incrementFeedBlocked()`.

Apague `FeedScrollLimitRule.kt` e `ScrollActivityAccumulator.kt`.

- [ ] **Step 3: Verde**

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: todos passam.

---

### Task 4: `FeedTimeTracker`

**Files:**
- Create: `android/.../detection/FeedTimeTracker.kt`
- Test: `android/app/src/test/.../detection/FeedTimeTrackerTest.kt`

**Interfaces:**
- Consumes: `StatsStore.addFeedMillis`, `feedMillisToday` (Task 3).
- Produces: `class FeedTimeTracker(stats: StatsStore, clock: () -> Long = System::currentTimeMillis, startOfDay: (Long) -> Long = ::startOfLocalDay)`
  com `update(onHomeTab: Boolean)`, `stop()`, `usedTodayMillis(): Long`,
  `val isCounting: Boolean`; e `fun startOfLocalDay(millis: Long): Long`.

- [ ] **Step 1: Testes que falham**

```kotlin
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.InMemoryKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FeedTimeTrackerTest {
    private val day = 86_400_000L
    private var now = 10 * day + 8 * 3_600_000L // day 10, 08:00
    private val stats = StatsStore(InMemoryKeyValueStore(), today = { "day-${now / day}" })
    private val tracker = FeedTimeTracker(stats, clock = { now }, startOfDay = { it / day * day })

    @Test
    fun `counts only while the home tab is on screen`() {
        tracker.update(onHomeTab = true)
        now += 30_000
        tracker.update(onHomeTab = false) // switched to DMs
        now += 60_000
        tracker.update(onHomeTab = true)
        now += 10_000

        assertEquals(40_000L, tracker.usedTodayMillis())
    }

    @Test
    fun `repeated events on the home tab don't restart or double count`() {
        tracker.update(onHomeTab = true)
        repeat(5) {
            now += 1_000
            tracker.update(onHomeTab = true)
        }

        assertEquals(5_000L, tracker.usedTodayMillis())
        assertTrue(tracker.isCounting)
    }

    @Test
    fun `stop closes the interval, e g screen off`() {
        tracker.update(onHomeTab = true)
        now += 20_000
        tracker.stop()
        now += 600_000 // screen off for 10 minutes

        assertEquals(20_000L, tracker.usedTodayMillis())
        assertFalse(tracker.isCounting)
    }

    @Test
    fun `persists across tracker instances within the same day`() {
        tracker.update(onHomeTab = true)
        now += 15_000
        tracker.stop()

        val restarted = FeedTimeTracker(stats, clock = { now }, startOfDay = { it / day * day })
        assertEquals(15_000L, restarted.usedTodayMillis())
    }

    @Test
    fun `an interval spanning midnight only counts from midnight on`() {
        now = 10 * day + day - 60_000 // 23:59
        tracker.update(onHomeTab = true)
        now += 180_000 // 00:02 of day 11

        assertEquals(120_000L, tracker.usedTodayMillis())
        tracker.stop()
        assertEquals(120_000L, stats.feedMillisToday())
    }
}
```

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: FAIL de compilação.

- [ ] **Step 2: Implementar**

```kotlin
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.StatsStore
import java.util.Calendar

/**
 * Adds up today's time with Instagram's Home tab on screen. An interval opens
 * when the tab becomes visible and closes when it stops being visible (another
 * tab, another app, screen off); only closed intervals are written to
 * [StatsStore], the open one is added on read. Time before today's midnight is
 * dropped: the limit is per calendar day.
 */
class FeedTimeTracker(
    private val stats: StatsStore,
    private val clock: () -> Long = System::currentTimeMillis,
    private val startOfDay: (Long) -> Long = ::startOfLocalDay
) {
    private var openSince: Long? = null

    val isCounting: Boolean get() = openSince != null

    fun update(onHomeTab: Boolean) {
        val now = clock()
        val since = openSince
        if (onHomeTab && since == null) {
            openSince = now
        } else if (!onHomeTab && since != null) {
            stats.addFeedMillis(countable(since, now))
            openSince = null
        }
    }

    fun stop() = update(onHomeTab = false)

    fun usedTodayMillis(): Long {
        val now = clock()
        val pending = openSince?.let { countable(it, now) } ?: 0L
        return stats.feedMillisToday() + pending
    }

    private fun countable(since: Long, now: Long): Long = now - maxOf(since, startOfDay(now))
}

fun startOfLocalDay(millis: Long): Long = Calendar.getInstance().apply {
    timeInMillis = millis
    set(Calendar.HOUR_OF_DAY, 0)
    set(Calendar.MINUTE, 0)
    set(Calendar.SECOND, 0)
    set(Calendar.MILLISECOND, 0)
}.timeInMillis
```

- [ ] **Step 3: Verde**

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: todos passam.

---

### Task 5: `FeedTimeLimitRule`

**Files:**
- Create: `android/.../detection/FeedTimeLimitRule.kt`
- Test: `android/app/src/test/.../detection/FeedTimeLimitRuleTest.kt`

**Interfaces:**
- Consumes: `HomeTabDetector` (Task 2), `FeedTimeTracker` (Task 4), `AppSettings.feedLimit*` (Task 3).
- Produces: `class FeedTimeLimitRule(settingsStore: SettingsStore, tracker: FeedTimeTracker, clock: () -> Long = System::currentTimeMillis, graceMs: Long = GRACE_MS) : DetectionRule`,
  com `fun millisUntilNextCheck(): Long?` e `companion object { const val GRACE_MS = 5_000L }`.

- [ ] **Step 1: Testes que falham**

```kotlin
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.InMemoryKeyValueStore
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.StatsStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class FeedTimeLimitRuleTest {
    private var now = 1_000_000L
    private val keyValues = InMemoryKeyValueStore()
    private val settings = SettingsStore(keyValues).apply {
        setSettings(AppSettings.DEFAULT.copy(feedLimitEnabled = true, feedLimitMinutes = 1))
    }
    private val stats = StatsStore(keyValues, today = { "today" })
    private val tracker = FeedTimeTracker(stats, clock = { now }, startOfDay = { 0L })
    private val rule = FeedTimeLimitRule(settings, tracker, clock = { now })

    private fun screen(homeSelected: Boolean) = ScreenNode(
        viewId = "root", contentDescription = null, className = "FrameLayout",
        children = listOf(
            ScreenNode("feed_tab", "Página inicial", "FrameLayout", isSelected = homeSelected),
            ScreenNode("direct_tab", "Direct", "FrameLayout", isSelected = !homeSelected)
        )
    )
    private val onHome = screen(homeSelected = true)
    private val onDirect = screen(homeSelected = false)
    private val event = 0

    @Test
    fun `lets the feed run until the daily limit, then blocks`() {
        assertEquals(RuleResult.NoAction, rule.evaluate(onHome, event))
        now += 59_000
        assertEquals(RuleResult.NoAction, rule.evaluate(onHome, event))
        now += 1_000
        assertEquals(RuleResult.Block(BlockReason.FEED_TIME_LIMIT), rule.evaluate(onHome, event))
    }

    @Test
    fun `time on other tabs doesn't count`() {
        rule.evaluate(onDirect, event)
        now += 120_000
        assertEquals(RuleResult.NoAction, rule.evaluate(onDirect, event))
    }

    @Test
    fun `leaving and coming back does not reset the daily count`() {
        rule.evaluate(onHome, event)
        now += 40_000
        rule.onSessionEnded()
        now += 3_600_000
        rule.evaluate(onDirect, event) // reopened on DMs (after the grace window)
        now += 10_000
        rule.evaluate(onHome, event)
        now += 20_000

        assertEquals(RuleResult.Block(BlockReason.FEED_TIME_LIMIT), rule.evaluate(onHome, event))
    }

    @Test
    fun `over the limit, opening Instagram grants 5 s to leave the home tab`() {
        rule.evaluate(onHome, event)
        now += 60_000
        rule.onSessionEnded() // kicked out

        rule.evaluate(onHome, event) // reopens on Início
        now += 4_000
        assertEquals(RuleResult.NoAction, rule.evaluate(onHome, event))
        now += 1_000
        assertEquals(RuleResult.Block(BlockReason.FEED_TIME_LIMIT), rule.evaluate(onHome, event))
    }

    @Test
    fun `mid-session return to the home tab after the limit blocks at once`() {
        rule.evaluate(onHome, event)
        now += 60_000
        rule.onSessionEnded()
        rule.evaluate(onHome, event)
        now += 2_000
        rule.evaluate(onDirect, event) // escaped to DMs within the grace window
        now += 30_000

        assertEquals(RuleResult.Block(BlockReason.FEED_TIME_LIMIT), rule.evaluate(onHome, event))
    }

    @Test
    fun `with the limit disabled time is still tracked but never blocks`() {
        settings.setSettings(settings.getSettings().copy(feedLimitEnabled = false))
        rule.evaluate(onHome, event)
        now += 300_000

        assertEquals(RuleResult.NoAction, rule.evaluate(onHome, event))
        assertEquals(300_000L, tracker.usedTodayMillis())
    }

    @Test
    fun `next check is due when the limit will be reached, or when the grace ends`() {
        rule.evaluate(onHome, event)
        now += 45_000
        assertEquals(15_000L, rule.millisUntilNextCheck())

        now += 15_000
        rule.onSessionEnded()
        rule.evaluate(onHome, event) // reopened over the limit
        now += 1_500
        assertEquals(3_500L, rule.millisUntilNextCheck())
    }

    @Test
    fun `no check is pending off the home tab or with the limit disabled`() {
        rule.evaluate(onDirect, event)
        assertNull(rule.millisUntilNextCheck())

        settings.setSettings(settings.getSettings().copy(feedLimitEnabled = false))
        rule.evaluate(onHome, event)
        assertNull(rule.millisUntilNextCheck())
    }
}
```

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: FAIL de compilação.

- [ ] **Step 2: Implementar**

```kotlin
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.SettingsStore

/**
 * Daily limit on time with Instagram's Home tab open. Time is tracked even with
 * the limit off (the Home screen shows it); blocking needs the limit on. Once
 * over the limit, opening Instagram (which always lands on Home) grants
 * [graceMs] to switch to another tab; returning to Home later blocks at once.
 */
class FeedTimeLimitRule(
    private val settingsStore: SettingsStore,
    private val tracker: FeedTimeTracker,
    private val clock: () -> Long = System::currentTimeMillis,
    private val graceMs: Long = GRACE_MS
) : DetectionRule {
    private var sessionStartedAt: Long? = null

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        val now = clock()
        val sessionStart = sessionStartedAt ?: now.also { sessionStartedAt = it }
        val onHomeTab = HomeTabDetector.isHomeTabSelected(root)
        tracker.update(onHomeTab)

        val settings = settingsStore.getSettings()
        val blocks = onHomeTab &&
            settings.feedLimitEnabled &&
            tracker.usedTodayMillis() >= limitMillis(settings) &&
            now - sessionStart >= graceMs
        return if (blocks) RuleResult.Block(BlockReason.FEED_TIME_LIMIT) else RuleResult.NoAction
    }

    /**
     * When the service should re-read the screen even without new events (the
     * user may just sit on the feed): at the limit, or when the grace ends.
     * Null when nothing can block without a new event.
     */
    fun millisUntilNextCheck(): Long? {
        val settings = settingsStore.getSettings()
        if (!settings.feedLimitEnabled || !tracker.isCounting) return null
        val remaining = limitMillis(settings) - tracker.usedTodayMillis()
        if (remaining > 0) return remaining
        val sessionStart = sessionStartedAt ?: return 0L
        return maxOf(0L, graceMs - (clock() - sessionStart))
    }

    override fun onSessionEnded() {
        tracker.stop()
        sessionStartedAt = null
    }

    private fun limitMillis(settings: AppSettings) = settings.feedLimitMinutes * 60_000L

    companion object {
        const val GRACE_MS = 5_000L
    }
}
```

- [ ] **Step 3: Verde**

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: todos passam.

---

### Task 6: Serviço — regra nova, timer de prazo, tela desligada e fim de sessão confiável

**Files:**
- Create: `android/.../detection/SessionBoundary.kt`
- Modify: `android/.../VaiViverAccessibilityService.kt`
- Test: `android/app/src/test/.../detection/SessionBoundaryTest.kt`

**Interfaces:**
- Consumes: `FeedTimeLimitRule`, `FeedTimeTracker`, `describeSelectedNodes`.
- Produces: `const val INSTAGRAM_PACKAGE = "com.instagram.android"`;
  `fun isLeavingInstagram(eventPackage: String?, eventType: Int, activeWindowPackage: String?): Boolean`.

- [ ] **Step 1: Teste que falha**

```kotlin
package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionBoundaryTest {
    @Test
    fun `another app taking the active window ends the session`() {
        assertTrue(isLeavingInstagram("com.miui.home", TYPE_WINDOW_STATE_CHANGED, "com.miui.home"))
    }

    @Test
    fun `a dialog from another package over Instagram does not (keyboard, volume, notification)`() {
        assertFalse(isLeavingInstagram("com.android.systemui", TYPE_WINDOW_STATE_CHANGED, INSTAGRAM_PACKAGE))
    }

    @Test
    fun `non window-state events from other packages are ignored`() {
        assertFalse(isLeavingInstagram("com.whatsapp", TYPE_WINDOW_CONTENT_CHANGED, "com.whatsapp"))
    }

    @Test
    fun `events without a package are ignored`() {
        assertFalse(isLeavingInstagram(null, TYPE_WINDOW_STATE_CHANGED, null))
    }
}
```

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: FAIL de compilação.

- [ ] **Step 2: Implementar `SessionBoundary.kt`**

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
 */
fun isLeavingInstagram(eventPackage: String?, eventType: Int, activeWindowPackage: String?): Boolean =
    eventPackage != null &&
        eventPackage != INSTAGRAM_PACKAGE &&
        eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
        activeWindowPackage != INSTAGRAM_PACKAGE
```

- [ ] **Step 3: Reescrever o serviço**

`VaiViverAccessibilityService.kt` completo:

```kotlin
package com.sorayaferreira.vaiviver

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.SharedPreferencesKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import com.sorayaferreira.vaiviver.detection.BlockReason
import com.sorayaferreira.vaiviver.detection.DetectionRule
import com.sorayaferreira.vaiviver.detection.FeedTimeLimitRule
import com.sorayaferreira.vaiviver.detection.FeedTimeTracker
import com.sorayaferreira.vaiviver.detection.INSTAGRAM_PACKAGE
import com.sorayaferreira.vaiviver.detection.ReelsTabRule
import com.sorayaferreira.vaiviver.detection.RuleResult
import com.sorayaferreira.vaiviver.detection.ScreenNode
import com.sorayaferreira.vaiviver.detection.describeSelectedNodes
import com.sorayaferreira.vaiviver.detection.evaluateRules
import com.sorayaferreira.vaiviver.detection.isLeavingInstagram
import com.sorayaferreira.vaiviver.detection.toScreenNode

class VaiViverAccessibilityService : AccessibilityService() {

    private lateinit var settingsStore: SettingsStore
    private lateinit var statsStore: StatsStore
    private lateinit var feedRule: FeedTimeLimitRule
    private lateinit var rules: List<DetectionRule>
    private var countedThisSession = false
    private var lastTabLog: List<String>? = null

    private val handler = Handler(Looper.getMainLooper())

    // Re-reads the screen when the feed limit (or the grace window) runs out,
    // for when the user sits on the feed and no events arrive.
    private val deadlineCheck = Runnable { checkInstagramWindow(eventType = 0) }

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = endSession()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        settingsStore = SettingsStore(keyValueStore)
        statsStore = StatsStore(keyValueStore)
        feedRule = FeedTimeLimitRule(settingsStore, FeedTimeTracker(statsStore))
        rules = listOf(ReelsTabRule(settingsStore), feedRule)

        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOffReceiver, filter)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventPackage = event.packageName?.toString()
        if (eventPackage == INSTAGRAM_PACKAGE) {
            checkInstagramWindow(event.eventType)
        } else if (isLeavingInstagram(eventPackage, event.eventType, activeWindowPackage())) {
            endSession()
        }
    }

    /** Reads the active window only if it is Instagram's (RF11) and applies the rules. */
    private fun checkInstagramWindow(eventType: Int) {
        val rootNode = rootInActiveWindow ?: return // transient null: skip, don't crash
        if (rootNode.packageName?.toString() != INSTAGRAM_PACKAGE) {
            rootNode.recycle()
            return
        }
        val screenNode = try {
            rootNode.toScreenNode()
        } finally {
            rootNode.recycle()
        }
        logSelectedTabs(screenNode)

        when (val result = evaluateRules(rules, screenNode, eventType)) {
            is RuleResult.Block -> {
                // Going Home on every matching event keeps enforcement robust against a
                // missed event; stats are counted only once per logical block (session).
                performGlobalAction(GLOBAL_ACTION_HOME)
                if (!countedThisSession) {
                    countedThisSession = true
                    when (result.reason) {
                        BlockReason.REELS_TAB -> statsStore.incrementReelsBlocked()
                        BlockReason.FEED_TIME_LIMIT -> statsStore.incrementFeedBlocked()
                    }
                }
            }
            RuleResult.NoAction -> Unit
        }
        scheduleDeadlineCheck()
    }

    private fun scheduleDeadlineCheck() {
        handler.removeCallbacks(deadlineCheck)
        feedRule.millisUntilNextCheck()?.let { delay ->
            handler.postDelayed(deadlineCheck, delay.coerceAtLeast(MIN_CHECK_DELAY_MS))
        }
    }

    @Suppress("DEPRECATION") // recycle() is a no-op on API 33+, kept for older devices
    private fun activeWindowPackage(): String? {
        val root = rootInActiveWindow ?: return null
        return try {
            root.packageName?.toString()
        } finally {
            root.recycle()
        }
    }

    private fun endSession() {
        handler.removeCallbacks(deadlineCheck)
        rules.forEach { it.onSessionEnded() }
        countedThisSession = false
    }

    /** Debug builds only: logs the selected nodes whenever they change. */
    private fun logSelectedTabs(screen: ScreenNode) {
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        val summary = describeSelectedNodes(screen)
        if (summary != lastTabLog) {
            lastTabLog = summary
            Log.d(TAG, "selected: $summary")
        }
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        runCatching { unregisterReceiver(screenOffReceiver) }
        super.onDestroy()
    }

    companion object {
        private const val TAG = "VaiViver/tabs"
        private const val MIN_CHECK_DELAY_MS = 500L
    }
}
```

`accessibility_service_config.xml`: remova `|typeViewScrolled` de
`accessibilityEventTypes`, que ninguém usa mais.

- [ ] **Step 4: Verde + build**

Run: `cd android && ./gradlew testDebugUnitTest -q` → Expected: todos passam.
Run: `.fvm/flutter_sdk/bin/flutter build apk --debug` → Expected: APK gerado.

---

### Task 7: Flutter — modelos, repositórios, configurações e Home

**Files:**
- Create: `lib/domain/feed_limit_steps.dart`, `test/domain/feed_limit_steps_test.dart`
- Modify: `lib/domain/models/app_settings.dart`, `lib/domain/models/daily_stats.dart`,
  `lib/data/method_channel_settings_repository.dart`,
  `lib/data/method_channel_stats_repository.dart`,
  `lib/features/settings/settings_view_model.dart`,
  `lib/features/settings/app_settings_form.dart`, `lib/features/home/home_screen.dart`
- Test: `test/domain/app_settings_test.dart`, `test/data/method_channel_*_test.dart`,
  `test/features/settings/*_test.dart`, `test/features/stats/stats_view_model_test.dart`,
  `test/features/home/home_screen_test.dart`, `test/fakes/*` (onde usarem os campos antigos)

**Interfaces:**
- Produces:
  - `AppSettings({reelsBlockEnabled, feedLimitEnabled, feedLimitMinutes})`,
    `defaults = (true, true, 20)`, `copyWith` com os mesmos nomes.
  - `DailyStats({reelsBlockedCount, feedSecondsToday, feedBlockedCount})`, `empty`.
  - `int nextFeedLimit(int minutes)`, `int previousFeedLimit(int minutes)`.
  - `SettingsViewModel.setFeedLimitEnabled(bool)` e `setFeedLimitMinutes(int)`.
  - Keys: `feed-limit-switch`, `feed-limit-decrement` e `feed-limit-increment`
    (substituem as `scroll-limit-*`); `reels-block-switch` não muda.

- [ ] **Step 1: Testes que falham**

`test/domain/feed_limit_steps_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/feed_limit_steps.dart';

void main() {
  test('1-minute steps up to 5, then 5-minute steps', () {
    expect(nextFeedLimit(1), 2);
    expect(nextFeedLimit(4), 5);
    expect(nextFeedLimit(5), 10);
    expect(nextFeedLimit(20), 25);
  });

  test('going down mirrors going up and never drops below 1', () {
    expect(previousFeedLimit(25), 20);
    expect(previousFeedLimit(10), 5);
    expect(previousFeedLimit(5), 4);
    expect(previousFeedLimit(2), 1);
    expect(previousFeedLimit(1), 1);
  });
}
```

Nos testes existentes, faça as trocas mecânicas: `scrollLimitEnabled` →
`feedLimitEnabled`, `scrollLimitMinutes` → `feedLimitMinutes`,
`scrollSecondsSaved` → `feedSecondsToday` (e acrescente `feedBlockedCount` onde se
monta ou lê `DailyStats`/o mapa do canal), as keys `scroll-limit-*` →
`feed-limit-*`. No teste do stepper de Configurações, o valor esperado depois de
tocar em "+" a partir do padrão (20) passa a ser **25**. Em `app_settings_test.dart`,
acrescente `expect(AppSettings.defaults.feedLimitMinutes, 20);`.

Em `home_screen_test.dart`:
- `_wrap` passa a incluir sempre
  `settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository())` antes das
  overrides recebidas (importe o fake e `settings_view_model.dart`);
- `DailyStats(reelsBlockedCount: 4, scrollSecondsSaved: 300)` →
  `DailyStats(reelsBlockedCount: 4, feedSecondsToday: 300, feedBlockedCount: 1)`
  (o mesmo padrão nos outros usos, e no teste de layout `feedBlockedCount: 3`);
- `'Minutos de scroll evitados hoje: 5 min'` → `'Tempo no Feed hoje: 5 de 20 min'`,
  e `'…: 10 min'` → `'Tempo no Feed hoje: 10 de 20 min'`;
- no primeiro teste, acrescente
  `expect(find.bySemanticsLabel('Saídas forçadas do Feed hoje: 1'), findsOneWidget);`.

Run: `.fvm/flutter_sdk/bin/flutter test` → Expected: FAIL (compilação e rótulos).

- [ ] **Step 2: Implementar**

`lib/domain/feed_limit_steps.dart`:

```dart
/// Minutes the daily feed limit stepper moves through: 1-minute steps up to 5
/// (handy for testing on the device), then 5-minute steps.
int nextFeedLimit(int minutes) => minutes < 5 ? minutes + 1 : minutes + 5;

int previousFeedLimit(int minutes) {
  if (minutes > 5) return minutes - 5;
  return minutes > 1 ? minutes - 1 : 1;
}
```

`app_settings.dart`: renomeie os campos para `feedLimitEnabled`/`feedLimitMinutes`,
padrão `feedLimitMinutes: 20`. `daily_stats.dart`:

```dart
class DailyStats {
  const DailyStats({
    required this.reelsBlockedCount,
    required this.feedSecondsToday,
    required this.feedBlockedCount,
  });

  final int reelsBlockedCount;
  final int feedSecondsToday;
  final int feedBlockedCount;

  static const empty = DailyStats(
    reelsBlockedCount: 0,
    feedSecondsToday: 0,
    feedBlockedCount: 0,
  );
}
```

Repositórios: as chaves do mapa são as mesmas do bridge (Task 3). O
`SettingsViewModel` ganha `setFeedLimitEnabled` e `setFeedLimitMinutes`, no lugar
dos de scroll.

`app_settings_form.dart`: o segundo switch passa a ser
`key: Key('feed-limit-switch')`, com o título `'Limite diário no Feed'`, e o
`_MinutesStepper` passa a:
- ter o rótulo `'Minutos por dia no Feed'`;
- usar as keys `feed-limit-decrement`/`feed-limit-increment`;
- usar `onChanged(previousFeedLimit(minutes))` e `onChanged(nextFeedLimit(minutes))`;
- deixar o "−" habilitado só com `enabled && minutes > 1`.

`home_screen.dart`: o `build` passa a observar também `settingsViewModelProvider`
(importe-o) e a passar `feedLimit: settings.value` para o `_StatsCard`, que fica:

```dart
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.feedLimit});

  final DailyStats stats;

  /// Null while settings load; the card then shows plain minutes.
  final AppSettings? feedLimit;

  @override
  Widget build(BuildContext context) {
    final feedMinutes = stats.feedSecondsToday ~/ 60;
    final limit = feedLimit;
    return GlassCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          StatValue(
            value: '$feedMinutes',
            unit: limit != null && limit.feedLimitEnabled
                ? 'de ${limit.feedLimitMinutes} min'
                : 'min',
            label: 'Tempo no Feed hoje',
          ),
          StatValue(
            value: '${stats.reelsBlockedCount}',
            label: 'Reels bloqueados hoje',
          ),
          StatValue(
            value: '${stats.feedBlockedCount}',
            label: 'Saídas forçadas do Feed hoje',
          ),
        ],
      ),
    );
  }
}
```

(importe `app_settings.dart`).

- [ ] **Step 3: Verde + qualidade**

Run: `.fvm/flutter_sdk/bin/dart format lib test && .fvm/flutter_sdk/bin/flutter analyze && .fvm/flutter_sdk/bin/flutter test`
Expected: sem issues, tudo verde. `grep -rn "scroll[A-Z]\|scroll-limit\|Scroll" lib test`
não deve achar nada ligado à regra antiga (`ScrollView`/`scroll` de layout são outra
coisa).

---

### Task 8: Documentação

**Files:**
- Modify: `docs/requirements.md`, `docs/design.md`, `docs/manual-test-checklist.md`

- [ ] **Step 1: `requirements.md`**

Substitua as linhas RF03 a RF08 e remova a RL04 (renumere RL05+ se houver):

```markdown
| RF03 | O sistema deve medir o tempo diário com a aba Início do Instagram na tela (Feed e telas abertas a partir dela), estando ou não rolando. |
| RF04 | O sistema deve permitir configurar o limite diário de tempo no Feed (padrão: 20 minutos). |
| RF05 | Ao atingir o limite diário, o sistema deve acionar `GLOBAL_ACTION_HOME` sempre que a aba Início estiver na tela — exceto nos primeiros 5 segundos após abrir o Instagram, para permitir ir a outra aba. |
| RF06 | O contador de tempo no Feed deve zerar à meia-noite (horário do aparelho); sair e voltar ao Instagram não o zera. |
| RF07 | O sistema deve permitir habilitar/desabilitar independentemente o bloqueio de Reels e o limite diário no Feed. |
| RF08 | O sistema deve exibir estatísticas diárias: bloqueios de Reels, tempo no Feed e saídas forçadas do Feed no dia corrente. |
```

- [ ] **Step 2: `design.md`**

- §1, item 2 → `**Tempo excessivo no Feed** — o app impõe um limite diário de tempo com a aba Início do Instagram aberta, configurável pela usuária.`
- §2: troque os bullets "O que conta como 'scroll'…", "Escopo do limite de scroll",
  "Valor do limite", "Reset do contador de scroll" e "Estatísticas no MVP" pelo
  conteúdo da seção "Decisões de design" deste plano (o que conta, reset diário,
  20 min, janela de 5 s, estatísticas), com uma nota: *"Mudança de 2026-09-28: a
  regra anterior media só rolagem ativa, por sessão; não funcionou no aparelho e foi
  trocada."* Em "Ação ao detectar a aba Reels", "limite de scroll" vira "limite do Feed".
- §3.2: `FeedScrollLimitRule` → `FeedTimeLimitRule`, e o bullet do "Leaky Bucket"
  vira: *"**Intervalos + prazo:** `FeedTimeTracker` soma intervalos com a aba Início
  na tela, marcados pelos eventos que o serviço já recebe; um timer agendado para o
  instante do limite relê a tela uma vez, cobrindo o caso de ficar parada no Feed
  (sem eventos). `ACTION_SCREEN_OFF` fecha o intervalo."*
- §4.1: "resetar o contador de scroll da sessão" → "encerrar a sessão (janela de 5 s,
  contagem de bloqueios)". Remova "e `TYPE_VIEW_SCROLLED` (…)".
- §4.2: no bullet de contagem, `FeedScrollLimitRule` → `FeedTimeLimitRule`. O bullet
  "Reset de sessão pode disparar por engano…" passa a **corrigido**: *"o fim de sessão
  agora exige que a janela ativa não seja mais do Instagram (`isLeavingInstagram`) —
  teclado, volume e notificações não encerram a sessão."*
- §5 passo 4 e §6 (Home e Configurações): textos novos ("Limite diário no Feed",
  "Minutos por dia no Feed", padrão 20; card "Tempo no Feed hoje: N de 20 min",
  "Reels bloqueados hoje", "Saídas forçadas do Feed hoje").
- §7: chaves `feed_limit_enabled`, `feed_limit_minutes`, `stats_feed_millis_<data>`
  e `stats_feed_blocked_<data>`; "a cada evento de scroll" vira "a cada evento de
  acessibilidade".

- [ ] **Step 3: `manual-test-checklist.md`**

- Calibração (item 3): `FeedScrollLimitRule.FEED_TAB_VIEW_ID_KEYWORDS` →
  `HomeTabDetector.VIEW_ID_KEYWORDS`/`CONTENT_DESCRIPTIONS`, mais a dica: *"em build
  de debug, `adb logcat -s VaiViver/tabs` mostra os nós selecionados de cada tela"*.
- Item 8: "Configure o limite diário no Feed (ex: 1 minuto, pra testar mais rápido)…".
- A seção "Limite de scroll" vira "Limite diário no Feed", com os itens 11 a 13:

```markdown
11. Com "Limite diário no Feed" em 1 minuto, abra o Instagram na Início e
    **não toque em nada** por 1 minuto — o VaiViver deve te levar para a tela
    inicial mesmo sem rolagem.
12. Reabra o Instagram — ele abre na Início; você tem ~5 s para tocar em
    Direct/Buscar/Perfil. Nessas abas nada acontece; voltar para a Início te
    expulsa na hora. No dia seguinte (ou apagando os dados do app), o limite
    volta a valer do zero.
13. Apague a tela com o Instagram na Início por 2 minutos e volte: o tempo de
    tela apagada não pode ter contado (confira "Tempo no Feed hoje" na Home).
    Desative o limite: o tempo continua aparecendo na Home, mas nada é bloqueado.
```

- Item 16: "Minutos de scroll evitados hoje" → "Tempo no Feed hoje" e "Saídas
  forçadas do Feed hoje".
- Item 18: reescreva como verificação da correção: *"Na Início, abra o teclado (busca
  ou comentário), aperte o volume e puxe uma notificação — nada disso pode encerrar a
  sessão: depois do limite, voltar do teclado/volume para a Início deve expulsar na
  hora (sem nova janela de 5 s)."*

---

### Task 9: Calibração com o log real + verificação final (depende da Soraya)

**Files:**
- Modify: `android/.../detection/HomeTabDetector.kt` (listas), talvez
  `ReelsTabRule.kt`, e os testes correspondentes

- [ ] **Step 1: Aguardar o log da Tarefa 1.** É a única parada do plano. Com as
  linhas `VaiViver/tabs` das abas Início, Reels e Perfil em mãos:
  - se o nó da Início traz um `viewId`/`contentDescription` que as listas já cobrem,
    nada muda;
  - senão, acrescente o valor real às listas (teste primeiro: um caso em
    `HomeTabDetectorTest` com o valor exato do log, que falha antes da mudança);
  - se **nenhum** nó selecionado aparece na Início (o Instagram não marca
    `selected`), pare e rediscuta a detecção com a Soraya, sem chutar.
- [ ] **Step 2: Verificação completa**

```bash
(cd android && ./gradlew testDebugUnitTest -q)
.fvm/flutter_sdk/bin/dart format --output=none --set-exit-if-changed lib test
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter build apk --debug
git status --short
```

Expected: tudo verde, APK gerado e nada commitado.
- [ ] **Step 3: Entregar.** A Soraya roda os itens 11 a 13 e 18 do checklist no
  aparelho, revisa o diff e commita ela mesma.
