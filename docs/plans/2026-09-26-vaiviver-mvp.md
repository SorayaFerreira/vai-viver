# VaiViver MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the VaiViver Android app (Flutter + a native Kotlin Accessibility
Service) that blocks Instagram's Reels tab and caps active feed-scrolling time per
session, with a guided permissions onboarding flow and daily stats.

**Architecture:** Flutter UI follows MVVM via Riverpod (`AsyncNotifier` ViewModels
over `Provider`-injected Repository interfaces). Repository implementations call a
single `MethodChannel` into a native Kotlin module. On the native side, an
`AccessibilityService` dispatches events to a list of `DetectionRule` strategy
objects (Strategy Pattern); every Android-framework dependency (`SharedPreferences`,
permission checks, settings intents) is wrapped behind a small interface so the
business logic is unit-testable on the JVM without Robolectric or a device — the
same Dependency Inversion idea shows up at every native boundary (`KeyValueStore`,
`PermissionsChecker`), and again on the Flutter side as the Repository pattern.

**Tech Stack:** Flutter/Dart, `flutter_riverpod`, Kotlin, JUnit4, Android
`AccessibilityService`, `SharedPreferences`, Flutter `MethodChannel`.

**Spec:** `docs/design.md` (architecture, patterns, risks) and
`docs/requirements.md` (traceable requirements) — read both before starting.

## Global Constraints

- Plataforma-alvo: Android 13+ (RNF01). Sideload only, no Play Store (RNF02).
- MVVM on Flutter via Riverpod (RNF03). Repository Pattern for all persistence
  access from ViewModels (RNF04). Strategy Pattern for native detection rules
  (RNF05).
- Local persistence only, no backend, no network calls anywhere in this app
  (RNF06, RNF07). All UI copy is Brazilian Portuguese (RNF08).
- The blocking action is always `GLOBAL_ACTION_HOME` — never attempt to force-stop
  Instagram's process (RL01).
- Android `applicationId` / Kotlin package: `com.sorayaferreira.vaiviver`. Flutter
  project name: `vaiviver`.
- MethodChannel name (fixed across every task that touches it):
  `com.sorayaferreira.vaiviver/native`.
- **Never run `git commit` in this project** (per `CLAUDE.md`). Every task's last
  step stages changes with `git add` and stops — leave the commit itself to the
  project owner.

## Review Focus

- **`getRootInActiveWindow()` returns `null`** (mid-transition between windows) —
  the service must skip that event silently, never crash. Covered in Task 6.
- **Two rules could theoretically both match one event** — the dispatcher must
  apply exactly one action (first match wins) and never double-trigger Home or
  double-count stats. Covered in Task 6.
- **A `MethodChannel` call fails** (native side unreachable) — the Dart repository
  must surface a catchable error, and the ViewModel/UI must render an error state
  instead of hanging or crashing. Covered in Task 9 and Task 13.
- **A toggle is off in Settings but the underlying condition still occurs** (e.g.
  scroll limit disabled but the user keeps scrolling) — must never trigger Home,
  and must not silently accumulate time that "carries over" once re-enabled.
  Covered in Task 5.
- **Accessibility permission is revoked after being granted** — the Home screen's
  status card must reflect this live (re-checked on app resume), not show stale
  "protected" state. Covered in Task 13.

---

## File Structure

```
android/app/src/main/kotlin/com/sorayaferreira/vaiviver/
  MainActivity.kt
  NativeBridge.kt
  data/
    KeyValueStore.kt
    SharedPreferencesKeyValueStore.kt
    AppSettings.kt
    DailyStats.kt
    SettingsStore.kt
    StatsStore.kt
    PermissionsChecker.kt
    AndroidPermissionsChecker.kt
  detection/
    ScreenNode.kt
    ScreenNodeMapper.kt
    BlockReason.kt
    RuleResult.kt
    DetectionRule.kt
    RuleEvaluator.kt
    ScrollActivityAccumulator.kt
    ReelsTabRule.kt
    FeedScrollLimitRule.kt
  VaiViverAccessibilityService.kt
android/app/src/main/res/xml/accessibility_service_config.xml
android/app/src/main/AndroidManifest.xml (modified)
android/app/src/main/res/values/strings.xml (modified)
android/app/src/test/kotlin/com/sorayaferreira/vaiviver/
  data/ (InMemoryKeyValueStore.kt, FakePermissionsChecker.kt, SettingsStoreTest.kt,
         StatsStoreTest.kt, NativeBridgeTest.kt)
  detection/ (ScrollActivityAccumulatorTest.kt, ReelsTabRuleTest.kt,
              FeedScrollLimitRuleTest.kt, RuleEvaluatorTest.kt)

lib/
  main.dart
  domain/
    models/ (app_settings.dart, daily_stats.dart, permission_status.dart)
    repositories/ (settings_repository.dart, stats_repository.dart,
                    permissions_repository.dart)
  core/
    native_bridge.dart
  data/ (method_channel_settings_repository.dart,
         method_channel_stats_repository.dart,
         method_channel_permissions_repository.dart)
  features/
    settings/ (settings_view_model.dart, settings_screen.dart,
               app_settings_form.dart)
    stats/ (stats_view_model.dart)
    permissions/ (permissions_view_model.dart, permissions_screen.dart,
                  accessibility_status_tile.dart,
                  battery_optimization_status_tile.dart,
                  autostart_ack_tile.dart)
    home/ (home_screen.dart)
    onboarding/ (onboarding_flow_screen.dart, welcome_step.dart)
test/
  fakes/ (fake_settings_repository.dart, fake_stats_repository.dart,
          fake_permissions_repository.dart)
  domain/, data/, features/**/*_test.dart

docs/manual-test-checklist.md
```

---

### Task 1: Scaffold the Flutter project and Android module

**Files:**
- Create: whole Flutter project skeleton (via `flutter create`)
- Modify: `android/app/build.gradle.kts` (or `android/app/build.gradle` — see step 3)

**Interfaces:**
- Produces: a buildable Flutter app (`flutter test` and `flutter analyze` both
  pass on the placeholder scaffold), `flutter_riverpod` available as a dependency,
  JUnit4 available for Kotlin unit tests.

- [ ] **Step 1: Generate the Flutter project in the current directory**

```bash
flutter create --org com.sorayaferreira --project-name vaiviver .
```

This adds `lib/`, `android/`, `test/`, `pubspec.yaml`, etc. alongside the existing
`docs/`, `CLAUDE.md`, and `.git/` — it does not touch those.

- [ ] **Step 2: Add Riverpod**

```bash
flutter pub add flutter_riverpod
```

- [ ] **Step 3: Add JUnit4 to the Android module's test dependencies**

Open `android/app/build.gradle.kts` (Groovy `build.gradle` if your Flutter version
scaffolds that instead) and add inside the `dependencies { ... }` block:

```kotlin
testImplementation("junit:junit:4.13.2")
```

- [ ] **Step 4: Verify the scaffold builds and its placeholder test passes**

Run: `flutter test`
Expected: PASS (the default `widget_test.dart` Flutter generates).

- [ ] **Step 5: Stage the changes (do not commit)**

```bash
git add pubspec.yaml pubspec.lock android lib test ios web macos linux windows .metadata .gitignore
git status
```

---

### Task 2: Native key-value storage abstraction

**Files:**
- Create: `android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/KeyValueStore.kt`
- Create: `android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/SharedPreferencesKeyValueStore.kt`
- Test/Fake: `android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/InMemoryKeyValueStore.kt`
- Test: `android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/InMemoryKeyValueStoreTest.kt`

**Interfaces:**
- Produces: `KeyValueStore` interface (`getString`, `putString`, `getInt`,
  `putInt`, `getBoolean`, `putBoolean`), `SharedPreferencesKeyValueStore`
  (real Android implementation), `InMemoryKeyValueStore` (test fake — used by
  Tasks 3 and 7's tests).

This is the first of several native boundaries wrapped behind an interface so the
logic built on top never has to touch the Android framework directly in tests —
the same idea as the Repository pattern on the Flutter side, just one layer down.

- [ ] **Step 1: Write the failing test for the fake** (the fake is what later
  tasks' tests depend on, so it earns its own test)

```kotlin
package com.sorayaferreira.vaiviver.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class InMemoryKeyValueStoreTest {
    @Test
    fun `returns defaults when nothing was stored`() {
        val store = InMemoryKeyValueStore()
        assertNull(store.getString("missing"))
        assertEquals(42, store.getInt("missing", 42))
        assertEquals(true, store.getBoolean("missing", true))
    }

    @Test
    fun `round-trips stored values`() {
        val store = InMemoryKeyValueStore()
        store.putString("s", "hello")
        store.putInt("i", 7)
        store.putBoolean("b", true)

        assertEquals("hello", store.getString("s"))
        assertEquals(7, store.getInt("i", 0))
        assertEquals(true, store.getBoolean("b", false))
    }
}
```

- [ ] **Step 2: Run it to verify it fails to compile** (types don't exist yet)

Run: `flutter test` is Dart-only; for the Android module run:
`cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.data.InMemoryKeyValueStoreTest"`
Expected: FAIL — `KeyValueStore`/`InMemoryKeyValueStore` unresolved references.

- [ ] **Step 3: Create the interface**

```kotlin
package com.sorayaferreira.vaiviver.data

interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun getInt(key: String, default: Int): Int
    fun putInt(key: String, value: Int)
    fun getBoolean(key: String, default: Boolean): Boolean
    fun putBoolean(key: String, value: Boolean)
}
```

- [ ] **Step 4: Create the in-memory fake**

```kotlin
package com.sorayaferreira.vaiviver.data

class InMemoryKeyValueStore : KeyValueStore {
    private val strings = mutableMapOf<String, String>()
    private val ints = mutableMapOf<String, Int>()
    private val booleans = mutableMapOf<String, Boolean>()

    override fun getString(key: String): String? = strings[key]
    override fun putString(key: String, value: String) { strings[key] = value }
    override fun getInt(key: String, default: Int): Int = ints[key] ?: default
    override fun putInt(key: String, value: Int) { ints[key] = value }
    override fun getBoolean(key: String, default: Boolean): Boolean = booleans[key] ?: default
    override fun putBoolean(key: String, value: Boolean) { booleans[key] = value }
}
```

- [ ] **Step 5: Create the real Android implementation**

```kotlin
package com.sorayaferreira.vaiviver.data

import android.content.Context

class SharedPreferencesKeyValueStore(context: Context) : KeyValueStore {
    private val prefs = context.getSharedPreferences("vai_viver_prefs", Context.MODE_PRIVATE)

    override fun getString(key: String): String? = prefs.getString(key, null)
    override fun putString(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }
    override fun getInt(key: String, default: Int): Int = prefs.getInt(key, default)
    override fun putInt(key: String, value: Int) {
        prefs.edit().putInt(key, value).apply()
    }
    override fun getBoolean(key: String, default: Boolean): Boolean = prefs.getBoolean(key, default)
    override fun putBoolean(key: String, value: Boolean) {
        prefs.edit().putBoolean(key, value).apply()
    }
}
```

`SharedPreferencesKeyValueStore` itself has no automated test — it's a thin,
one-line-per-method wrapper around the real Android API, and is exercised by the
manual test checklist (Task 18) instead.

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.data.InMemoryKeyValueStoreTest"`
Expected: PASS

- [ ] **Step 7: Stage the changes (do not commit)**

```bash
git add android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/KeyValueStore.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/SharedPreferencesKeyValueStore.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/InMemoryKeyValueStore.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/InMemoryKeyValueStoreTest.kt
git status
```

---

### Task 3: Settings and stats storage

**Files:**
- Create: `android/.../data/AppSettings.kt`, `DailyStats.kt`, `SettingsStore.kt`, `StatsStore.kt`
- Test: `android/.../test/.../data/SettingsStoreTest.kt`, `StatsStoreTest.kt`

**Interfaces:**
- Consumes: `KeyValueStore`, `InMemoryKeyValueStore` (Task 2).
- Produces: `AppSettings` (data class: `reelsBlockEnabled: Boolean`,
  `scrollLimitEnabled: Boolean`, `scrollLimitMinutes: Int`, companion `DEFAULT`),
  `DailyStats` (data class: `reelsBlockedCount: Int`, `scrollSecondsSaved: Int`,
  companion `EMPTY`), `SettingsStore(store: KeyValueStore)` with
  `getSettings(): AppSettings` / `setSettings(AppSettings)`, `StatsStore(store:
  KeyValueStore, today: () -> String = ...)` with `incrementReelsBlocked()`,
  `addScrollSecondsSaved(seconds: Int)`, `getToday(): DailyStats`.

- [ ] **Step 1: Write the failing tests**

```kotlin
// SettingsStoreTest.kt
package com.sorayaferreira.vaiviver.data

import org.junit.Assert.assertEquals
import org.junit.Test

class SettingsStoreTest {
    @Test
    fun `returns defaults when nothing was saved`() {
        val store = SettingsStore(InMemoryKeyValueStore())
        assertEquals(AppSettings.DEFAULT, store.getSettings())
    }

    @Test
    fun `round-trips saved settings`() {
        val store = SettingsStore(InMemoryKeyValueStore())
        val settings = AppSettings(
            reelsBlockEnabled = false,
            scrollLimitEnabled = true,
            scrollLimitMinutes = 5
        )

        store.setSettings(settings)

        assertEquals(settings, store.getSettings())
    }
}
```

```kotlin
// StatsStoreTest.kt
package com.sorayaferreira.vaiviver.data

import org.junit.Assert.assertEquals
import org.junit.Test

class StatsStoreTest {
    @Test
    fun `starts empty for a fresh day`() {
        val store = StatsStore(InMemoryKeyValueStore(), today = { "2026-09-26" })
        assertEquals(DailyStats.EMPTY, store.getToday())
    }

    @Test
    fun `accumulates reels-blocked count and scroll seconds saved for the same day`() {
        val store = StatsStore(InMemoryKeyValueStore(), today = { "2026-09-26" })

        store.incrementReelsBlocked()
        store.incrementReelsBlocked()
        store.addScrollSecondsSaved(120)

        val stats = store.getToday()
        assertEquals(2, stats.reelsBlockedCount)
        assertEquals(120, stats.scrollSecondsSaved)
    }

    @Test
    fun `keeps separate counters per day`() {
        var date = "2026-09-26"
        val store = StatsStore(InMemoryKeyValueStore(), today = { date })

        store.incrementReelsBlocked()
        date = "2026-09-27"

        assertEquals(0, store.getToday().reelsBlockedCount)
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.data.SettingsStoreTest" --tests "com.sorayaferreira.vaiviver.data.StatsStoreTest"`
Expected: FAIL — types unresolved.

- [ ] **Step 3: Create the models**

```kotlin
// AppSettings.kt
package com.sorayaferreira.vaiviver.data

data class AppSettings(
    val reelsBlockEnabled: Boolean,
    val scrollLimitEnabled: Boolean,
    val scrollLimitMinutes: Int
) {
    companion object {
        val DEFAULT = AppSettings(
            reelsBlockEnabled = true,
            scrollLimitEnabled = true,
            scrollLimitMinutes = 2
        )
    }
}
```

```kotlin
// DailyStats.kt
package com.sorayaferreira.vaiviver.data

data class DailyStats(
    val reelsBlockedCount: Int,
    val scrollSecondsSaved: Int
) {
    companion object {
        val EMPTY = DailyStats(reelsBlockedCount = 0, scrollSecondsSaved = 0)
    }
}
```

- [ ] **Step 4: Implement `SettingsStore`**

```kotlin
package com.sorayaferreira.vaiviver.data

class SettingsStore(private val store: KeyValueStore) {
    fun getSettings(): AppSettings = AppSettings(
        reelsBlockEnabled = store.getBoolean(KEY_REELS_BLOCK_ENABLED, AppSettings.DEFAULT.reelsBlockEnabled),
        scrollLimitEnabled = store.getBoolean(KEY_SCROLL_LIMIT_ENABLED, AppSettings.DEFAULT.scrollLimitEnabled),
        scrollLimitMinutes = store.getInt(KEY_SCROLL_LIMIT_MINUTES, AppSettings.DEFAULT.scrollLimitMinutes)
    )

    fun setSettings(settings: AppSettings) {
        store.putBoolean(KEY_REELS_BLOCK_ENABLED, settings.reelsBlockEnabled)
        store.putBoolean(KEY_SCROLL_LIMIT_ENABLED, settings.scrollLimitEnabled)
        store.putInt(KEY_SCROLL_LIMIT_MINUTES, settings.scrollLimitMinutes)
    }

    companion object {
        private const val KEY_REELS_BLOCK_ENABLED = "reels_block_enabled"
        private const val KEY_SCROLL_LIMIT_ENABLED = "scroll_limit_enabled"
        private const val KEY_SCROLL_LIMIT_MINUTES = "scroll_limit_minutes"
    }
}
```

- [ ] **Step 5: Implement `StatsStore`**

```kotlin
package com.sorayaferreira.vaiviver.data

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class StatsStore(
    private val store: KeyValueStore,
    private val today: () -> String = { defaultTodayKey() }
) {
    fun incrementReelsBlocked() {
        val key = reelsBlockedKey(today())
        store.putInt(key, store.getInt(key, 0) + 1)
    }

    fun addScrollSecondsSaved(seconds: Int) {
        val key = scrollSecondsKey(today())
        store.putInt(key, store.getInt(key, 0) + seconds)
    }

    fun getToday(): DailyStats {
        val date = today()
        return DailyStats(
            reelsBlockedCount = store.getInt(reelsBlockedKey(date), 0),
            scrollSecondsSaved = store.getInt(scrollSecondsKey(date), 0)
        )
    }

    private fun reelsBlockedKey(date: String) = "stats_reels_blocked_$date"
    private fun scrollSecondsKey(date: String) = "stats_scroll_seconds_saved_$date"

    companion object {
        fun defaultTodayKey(): String =
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.data.SettingsStoreTest" --tests "com.sorayaferreira.vaiviver.data.StatsStoreTest"`
Expected: PASS

- [ ] **Step 7: Stage the changes (do not commit)**

```bash
git add android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/AppSettings.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/DailyStats.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/SettingsStore.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/StatsStore.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/SettingsStoreTest.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/StatsStoreTest.kt
git status
```

---

### Task 4: Detection contracts and the scroll-activity accumulator

**Files:**
- Create: `android/.../detection/ScreenNode.kt`, `BlockReason.kt`, `RuleResult.kt`, `DetectionRule.kt`, `ScrollActivityAccumulator.kt`
- Test: `android/.../test/.../detection/ScrollActivityAccumulatorTest.kt`

**Interfaces:**
- Produces: `ScreenNode(viewId: String?, contentDescription: String?, className:
  String?, children: List<ScreenNode> = emptyList())` with `findFirst(predicate:
  (ScreenNode) -> Boolean): ScreenNode?`; `BlockReason` enum (`REELS_TAB`,
  `SCROLL_LIMIT`); `RuleResult` sealed class (`NoAction`, `Block(reason:
  BlockReason)`); `DetectionRule` interface (`evaluate(root: ScreenNode, eventType:
  Int): RuleResult`, `onSessionEnded()` defaulted to no-op);
  `ScrollActivityAccumulator(idleThresholdMs: Long = 400L, clock: () -> Long =
  System::currentTimeMillis)` with `onScrollEvent()`, `accumulatedMillis(): Long`,
  `reset()`.

This is the "leaky bucket" piece from `docs/design.md` section 3.2: it only counts
a gap between two scroll events toward the total if that gap is short enough to
count as "still scrolling" — a long pause starts a fresh burst instead.

- [ ] **Step 1: Write the failing tests**

```kotlin
package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Test

class ScrollActivityAccumulatorTest {
    @Test
    fun `accumulates the gap between quick consecutive scroll events`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })

        accumulator.onScrollEvent()
        now = 200L
        accumulator.onScrollEvent()
        now = 500L
        accumulator.onScrollEvent()

        assertEquals(500L, accumulator.accumulatedMillis())
    }

    @Test
    fun `does not accumulate a gap larger than the idle threshold`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })

        accumulator.onScrollEvent()
        now = 2000L
        accumulator.onScrollEvent()

        assertEquals(0L, accumulator.accumulatedMillis())
    }

    @Test
    fun `reset clears the accumulated time`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        accumulator.onScrollEvent()
        now = 100L
        accumulator.onScrollEvent()

        accumulator.reset()

        assertEquals(0L, accumulator.accumulatedMillis())
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.detection.ScrollActivityAccumulatorTest"`
Expected: FAIL — unresolved reference `ScrollActivityAccumulator`.

- [ ] **Step 3: Create the supporting types**

```kotlin
// ScreenNode.kt
package com.sorayaferreira.vaiviver.detection

data class ScreenNode(
    val viewId: String?,
    val contentDescription: String?,
    val className: String?,
    val children: List<ScreenNode> = emptyList()
) {
    fun findFirst(predicate: (ScreenNode) -> Boolean): ScreenNode? {
        if (predicate(this)) return this
        for (child in children) {
            child.findFirst(predicate)?.let { return it }
        }
        return null
    }
}
```

```kotlin
// BlockReason.kt
package com.sorayaferreira.vaiviver.detection

enum class BlockReason { REELS_TAB, SCROLL_LIMIT }
```

```kotlin
// RuleResult.kt
package com.sorayaferreira.vaiviver.detection

sealed class RuleResult {
    object NoAction : RuleResult()
    data class Block(val reason: BlockReason) : RuleResult()
}
```

```kotlin
// DetectionRule.kt
package com.sorayaferreira.vaiviver.detection

interface DetectionRule {
    fun evaluate(root: ScreenNode, eventType: Int): RuleResult
    fun onSessionEnded() {}
}
```

- [ ] **Step 4: Implement `ScrollActivityAccumulator`**

```kotlin
package com.sorayaferreira.vaiviver.detection

class ScrollActivityAccumulator(
    private val idleThresholdMs: Long = 400L,
    private val clock: () -> Long = System::currentTimeMillis
) {
    private var lastEventAt: Long? = null
    private var accumulatedMs: Long = 0L

    fun onScrollEvent() {
        val now = clock()
        lastEventAt?.let { last ->
            val gap = now - last
            if (gap in 0..idleThresholdMs) {
                accumulatedMs += gap
            }
        }
        lastEventAt = now
    }

    fun accumulatedMillis(): Long = accumulatedMs

    fun reset() {
        accumulatedMs = 0L
        lastEventAt = null
    }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.detection.ScrollActivityAccumulatorTest"`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/ScreenNode.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/BlockReason.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/RuleResult.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/DetectionRule.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/ScrollActivityAccumulator.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/ScrollActivityAccumulatorTest.kt
git status
```

---

### Task 5: The two detection rules (Strategy Pattern)

**Files:**
- Create: `android/.../detection/ReelsTabRule.kt`, `FeedScrollLimitRule.kt`
- Test: `android/.../test/.../detection/ReelsTabRuleTest.kt`, `FeedScrollLimitRuleTest.kt`

**Interfaces:**
- Consumes: `SettingsStore`, `StatsStore`, `AppSettings` (Task 3); `ScreenNode`,
  `DetectionRule`, `RuleResult`, `BlockReason`, `ScrollActivityAccumulator`
  (Task 4); `InMemoryKeyValueStore` (Task 2, for building test stores).
- Produces: `ReelsTabRule(settingsStore: SettingsStore) : DetectionRule`;
  `FeedScrollLimitRule(settingsStore: SettingsStore, statsStore: StatsStore,
  accumulator: ScrollActivityAccumulator = ScrollActivityAccumulator()) :
  DetectionRule`.

The matcher keywords below (`REELS_TAB_VIEW_ID_KEYWORDS`, etc.) are a best-effort
starting guess, not verified against a real Instagram install — per
`docs/design.md` section 4.2 this is an accepted, unavoidable risk. Task 18's
manual checklist is where you confirm/adjust them against the Instagram version
actually installed, using Android's "Accessibility Scanner" app or Android
Studio's Layout Inspector. Keeping them as named constants at the top of each
file is what makes that later adjustment a one-line change instead of a rewrite.

- [ ] **Step 1: Write the failing tests**

```kotlin
// ReelsTabRuleTest.kt
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.InMemoryKeyValueStore
import com.sorayaferreira.vaiviver.data.SettingsStore
import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.assertEquals
import org.junit.Test

class ReelsTabRuleTest {
    private fun settingsStore(reelsEnabled: Boolean = true) =
        SettingsStore(InMemoryKeyValueStore()).apply {
            setSettings(AppSettings.DEFAULT.copy(reelsBlockEnabled = reelsEnabled))
        }

    @Test
    fun `blocks when a reels tab marker is present in the tree`() {
        val root = ScreenNode(
            viewId = "root",
            contentDescription = null,
            className = "FrameLayout",
            children = listOf(
                ScreenNode(viewId = "bottom_nav_reels", contentDescription = "Reels", className = "ImageView")
            )
        )
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.Block(BlockReason.REELS_TAB), result)
    }

    @Test
    fun `does nothing when reels blocking is disabled`() {
        val root = ScreenNode("root", "Reels", "ImageView")
        val rule = ReelsTabRule(settingsStore(reelsEnabled = false))

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.NoAction, result)
    }

    @Test
    fun `does nothing when no reels tab marker is present`() {
        val root = ScreenNode("root", null, "FrameLayout")
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.NoAction, result)
    }
}
```

```kotlin
// FeedScrollLimitRuleTest.kt
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.InMemoryKeyValueStore
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.StatsStore
import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.assertEquals
import org.junit.Test

class FeedScrollLimitRuleTest {
    private val feedRoot = ScreenNode(viewId = "feed_tab_container", contentDescription = null, className = "FrameLayout")

    private fun settingsStore(scrollLimitEnabled: Boolean = true, minutes: Int = 2) =
        SettingsStore(InMemoryKeyValueStore()).apply {
            setSettings(AppSettings.DEFAULT.copy(scrollLimitEnabled = scrollLimitEnabled, scrollLimitMinutes = minutes))
        }

    @Test
    fun `blocks once accumulated scroll time exceeds the configured limit`() {
        var now = 0L
        val rule = FeedScrollLimitRule(
            settingsStore(minutes = 1),
            StatsStore(InMemoryKeyValueStore()),
            ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        )

        var result: RuleResult = RuleResult.NoAction
        repeat(310) {
            now += 200L
            result = rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }

        assertEquals(RuleResult.Block(BlockReason.SCROLL_LIMIT), result)
    }

    @Test
    fun `never blocks while the scroll limit is disabled`() {
        var now = 0L
        val rule = FeedScrollLimitRule(
            settingsStore(scrollLimitEnabled = false, minutes = 1),
            StatsStore(InMemoryKeyValueStore()),
            ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        )

        var result: RuleResult = RuleResult.NoAction
        repeat(310) {
            now += 200L
            result = rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }

        assertEquals(RuleResult.NoAction, result)
    }

    @Test
    fun `onSessionEnded resets accumulated scroll time`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        val rule = FeedScrollLimitRule(settingsStore(minutes = 1), StatsStore(InMemoryKeyValueStore()), accumulator)

        repeat(310) {
            now += 200L
            rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }
        rule.onSessionEnded()

        assertEquals(0L, accumulator.accumulatedMillis())
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.detection.ReelsTabRuleTest" --tests "com.sorayaferreira.vaiviver.detection.FeedScrollLimitRuleTest"`
Expected: FAIL — unresolved references.

- [ ] **Step 3: Implement `ReelsTabRule`**

```kotlin
package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.SettingsStore

class ReelsTabRule(private val settingsStore: SettingsStore) : DetectionRule {

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        if (!settingsStore.getSettings().reelsBlockEnabled) return RuleResult.NoAction

        val onReelsTab = root.findFirst { node ->
            REELS_TAB_VIEW_ID_KEYWORDS.any { keyword ->
                node.viewId?.contains(keyword, ignoreCase = true) == true
            } ||
                REELS_TAB_CONTENT_DESCRIPTIONS.any { desc ->
                    node.contentDescription?.equals(desc, ignoreCase = true) == true
                }
        } != null

        return if (onReelsTab) RuleResult.Block(BlockReason.REELS_TAB) else RuleResult.NoAction
    }

    companion object {
        // Melhor esforço — confirmar contra a versão real do Instagram instalada
        // (ver docs/manual-test-checklist.md).
        val REELS_TAB_VIEW_ID_KEYWORDS = listOf("clips_tab", "reels_tab")
        val REELS_TAB_CONTENT_DESCRIPTIONS = listOf("Reels")
    }
}
```

- [ ] **Step 4: Implement `FeedScrollLimitRule`**

```kotlin
package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.StatsStore

class FeedScrollLimitRule(
    private val settingsStore: SettingsStore,
    private val statsStore: StatsStore,
    private val accumulator: ScrollActivityAccumulator = ScrollActivityAccumulator()
) : DetectionRule {

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        val settings = settingsStore.getSettings()
        if (!settings.scrollLimitEnabled) return RuleResult.NoAction

        val onFeedTab = root.findFirst { node ->
            FEED_TAB_VIEW_ID_KEYWORDS.any { keyword ->
                node.viewId?.contains(keyword, ignoreCase = true) == true
            }
        } != null
        if (!onFeedTab) return RuleResult.NoAction

        if (eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
            accumulator.onScrollEvent()
        }

        val limitMs = settings.scrollLimitMinutes * 60_000L
        return if (accumulator.accumulatedMillis() >= limitMs) {
            RuleResult.Block(BlockReason.SCROLL_LIMIT)
        } else {
            RuleResult.NoAction
        }
    }

    override fun onSessionEnded() {
        accumulator.reset()
    }

    companion object {
        // Melhor esforço — confirmar contra a versão real do Instagram instalada.
        val FEED_TAB_VIEW_ID_KEYWORDS = listOf("feed_tab", "home_tab")
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.detection.ReelsTabRuleTest" --tests "com.sorayaferreira.vaiviver.detection.FeedScrollLimitRuleTest"`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/ReelsTabRule.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/FeedScrollLimitRule.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/ReelsTabRuleTest.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/FeedScrollLimitRuleTest.kt
git status
```

---

### Task 6: Rule dispatcher and the Accessibility Service

**Files:**
- Create: `android/.../detection/RuleEvaluator.kt`, `android/.../detection/ScreenNodeMapper.kt`, `android/.../VaiViverAccessibilityService.kt`
- Create: `android/app/src/main/res/xml/accessibility_service_config.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/strings.xml`
- Test: `android/.../test/.../detection/RuleEvaluatorTest.kt`

**Interfaces:**
- Consumes: `DetectionRule`, `RuleResult`, `ScreenNode` (Task 4); `ReelsTabRule`,
  `FeedScrollLimitRule` (Task 5); `SettingsStore`, `StatsStore`,
  `SharedPreferencesKeyValueStore` (Tasks 2-3).
- Produces: `fun evaluateRules(rules: List<DetectionRule>, root: ScreenNode,
  eventType: Int): RuleResult` (pure dispatcher — this is what Task 7's
  `NativeBridge` and any future rule additions build on); `VaiViverAccessibilityService`
  class (referenced by name from `PermissionsChecker` in Task 7 and from the
  manifest).

**Review Focus covered here:** null root node (must not crash) and "first match
wins" dispatch (must not double-trigger).

- [ ] **Step 1: Write the failing test for the dispatcher**

```kotlin
package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class RuleEvaluatorTest {
    @Test
    fun `returns the first blocking result and never calls later rules`() {
        val ruleA = object : DetectionRule {
            override fun evaluate(root: ScreenNode, eventType: Int) = RuleResult.Block(BlockReason.REELS_TAB)
        }
        val ruleB = object : DetectionRule {
            var called = false
            override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
                called = true
                return RuleResult.Block(BlockReason.SCROLL_LIMIT)
            }
        }

        val result = evaluateRules(listOf(ruleA, ruleB), ScreenNode(null, null, null), 0)

        assertEquals(RuleResult.Block(BlockReason.REELS_TAB), result)
        assertFalse(ruleB.called)
    }

    @Test
    fun `returns NoAction when no rule blocks`() {
        val rule = object : DetectionRule {
            override fun evaluate(root: ScreenNode, eventType: Int) = RuleResult.NoAction
        }

        assertEquals(RuleResult.NoAction, evaluateRules(listOf(rule), ScreenNode(null, null, null), 0))
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.detection.RuleEvaluatorTest"`
Expected: FAIL — `evaluateRules` unresolved.

- [ ] **Step 3: Implement the dispatcher**

```kotlin
package com.sorayaferreira.vaiviver.detection

fun evaluateRules(rules: List<DetectionRule>, root: ScreenNode, eventType: Int): RuleResult {
    for (rule in rules) {
        val result = rule.evaluate(root, eventType)
        if (result is RuleResult.Block) return result
    }
    return RuleResult.NoAction
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.detection.RuleEvaluatorTest"`
Expected: PASS

- [ ] **Step 5: Add the `AccessibilityNodeInfo` → `ScreenNode` adapter**

Not unit-tested (it calls real Android SDK methods that require a device or
Robolectric — out of scope per `docs/design.md` section 9); covered by Task 18's
manual checklist instead. Kept deliberately tiny to minimize untested surface.

```kotlin
package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityNodeInfo

@Suppress("DEPRECATION") // recycle() is a no-op on API 33+, kept for older devices
fun AccessibilityNodeInfo.toScreenNode(): ScreenNode {
    val children = mutableListOf<ScreenNode>()
    for (i in 0 until childCount) {
        val child = getChild(i) ?: continue
        children.add(child.toScreenNode())
        child.recycle()
    }
    return ScreenNode(
        viewId = viewIdResourceName,
        contentDescription = contentDescription?.toString(),
        className = className?.toString(),
        children = children
    )
}
```

- [ ] **Step 6: Implement the service**

```kotlin
package com.sorayaferreira.vaiviver

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.SharedPreferencesKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import com.sorayaferreira.vaiviver.detection.BlockReason
import com.sorayaferreira.vaiviver.detection.DetectionRule
import com.sorayaferreira.vaiviver.detection.FeedScrollLimitRule
import com.sorayaferreira.vaiviver.detection.ReelsTabRule
import com.sorayaferreira.vaiviver.detection.RuleResult
import com.sorayaferreira.vaiviver.detection.evaluateRules
import com.sorayaferreira.vaiviver.detection.toScreenNode

class VaiViverAccessibilityService : AccessibilityService() {

    private lateinit var settingsStore: SettingsStore
    private lateinit var statsStore: StatsStore
    private lateinit var rules: List<DetectionRule>

    override fun onServiceConnected() {
        super.onServiceConnected()
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        settingsStore = SettingsStore(keyValueStore)
        statsStore = StatsStore(keyValueStore)
        rules = listOf(
            ReelsTabRule(settingsStore),
            FeedScrollLimitRule(settingsStore, statsStore)
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventPackage = event.packageName?.toString()

        if (eventPackage != INSTAGRAM_PACKAGE) {
            // Any other app coming to the foreground ends the Instagram session.
            if (eventPackage != null) {
                rules.forEach { it.onSessionEnded() }
            }
            return
        }

        val rootNode = rootInActiveWindow ?: return // transient null: skip, don't crash
        val screenNode = try {
            rootNode.toScreenNode()
        } finally {
            rootNode.recycle()
        }

        when (val result = evaluateRules(rules, screenNode, event.eventType)) {
            is RuleResult.Block -> {
                performGlobalAction(GLOBAL_ACTION_HOME)
                when (result.reason) {
                    BlockReason.REELS_TAB -> statsStore.incrementReelsBlocked()
                    BlockReason.SCROLL_LIMIT -> statsStore.addScrollSecondsSaved(
                        settingsStore.getSettings().scrollLimitMinutes * 60
                    )
                }
            }
            RuleResult.NoAction -> Unit
        }
    }

    override fun onInterrupt() = Unit

    companion object {
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
    }
}
```

- [ ] **Step 7: Add the accessibility service config XML**

```xml
<!-- android/app/src/main/res/xml/accessibility_service_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged|typeViewScrolled"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="100"
    android:description="@string/accessibility_service_description" />
```

Note there is no `android:packageNames` attribute — see the note added to
`docs/design.md` section 4.1: this service needs system-wide window-state events
to detect when the user leaves Instagram, but only ever inspects screen *content*
for `com.instagram.android`.

- [ ] **Step 8: Add the description string**

Open `android/app/src/main/res/values/strings.xml` and add:

```xml
<string name="accessibility_service_description">O VaiViver usa este serviço para detectar a aba Reels e medir a rolagem no Feed do Instagram, e não lê conteúdo de nenhum outro aplicativo.</string>
```

- [ ] **Step 9: Register the service in the manifest**

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:

```xml
<service
    android:name=".VaiViverAccessibilityService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    android:exported="false">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config" />
</service>
```

- [ ] **Step 10: Confirm the Android module still compiles**

Run: `cd android && ./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 11: Stage the changes (do not commit)**

```bash
git add android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/RuleEvaluator.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/ScreenNodeMapper.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/VaiViverAccessibilityService.kt \
        android/app/src/main/res/xml/accessibility_service_config.xml \
        android/app/src/main/AndroidManifest.xml \
        android/app/src/main/res/values/strings.xml \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/detection/RuleEvaluatorTest.kt
git status
```

---

### Task 7: Permissions checker and the MethodChannel bridge

**Files:**
- Create: `android/.../data/PermissionsChecker.kt`, `AndroidPermissionsChecker.kt`, `android/.../NativeBridge.kt`
- Test/Fake: `android/.../test/.../data/FakePermissionsChecker.kt`
- Test: `android/.../test/.../data/NativeBridgeTest.kt`
- Modify: `android/.../MainActivity.kt`

**Interfaces:**
- Consumes: `SettingsStore`, `StatsStore`, `KeyValueStore` (Tasks 2-3);
  `VaiViverAccessibilityService` (Task 6, referenced by class for
  `ComponentName`).
- Produces: `PermissionsChecker` interface (`isAccessibilityServiceEnabled():
  Boolean`, `isIgnoringBatteryOptimizations(): Boolean`,
  `isAutostartAcknowledged(): Boolean`, `setAutostartAcknowledged(Boolean)`,
  `isOnboardingComplete(): Boolean`, `setOnboardingComplete(Boolean)`,
  `openAccessibilitySettings()`, `openBatteryOptimizationSettings()`);
  `AndroidPermissionsChecker` (real impl); `NativeBridge(settingsStore:
  SettingsStore, statsStore: StatsStore, permissionsChecker: PermissionsChecker)
  : MethodChannel.MethodCallHandler` handling methods `getSettings`,
  `setSettings`, `getTodayStats`, `getPermissionStatus`,
  `setAutostartAcknowledged`, `openAccessibilitySettings`,
  `openBatteryOptimizationSettings`, `getOnboardingComplete`,
  `setOnboardingComplete` on channel `com.sorayaferreira.vaiviver/native` —
  **these exact method names are what Task 9's Dart repositories call.**

`PermissionsChecker` is the third native boundary wrapped behind an interface
(after `KeyValueStore` and, implicitly, the accessibility service itself): it's
what makes `NativeBridge` fully unit-testable on the JVM, since `MethodCall` and
`MethodChannel.Result` are plain Flutter-embedding classes with no Android
framework dependency.

- [ ] **Step 1: Write the failing tests**

```kotlin
// FakePermissionsChecker.kt
package com.sorayaferreira.vaiviver.data

class FakePermissionsChecker(
    var accessibilityEnabled: Boolean = false,
    var batteryOptimizationIgnored: Boolean = false,
    private var autostartAcknowledged: Boolean = false,
    private var onboardingComplete: Boolean = false
) : PermissionsChecker {
    var openAccessibilitySettingsCallCount = 0
        private set
    var openBatteryOptimizationSettingsCallCount = 0
        private set

    override fun isAccessibilityServiceEnabled() = accessibilityEnabled
    override fun isIgnoringBatteryOptimizations() = batteryOptimizationIgnored
    override fun isAutostartAcknowledged() = autostartAcknowledged
    override fun setAutostartAcknowledged(value: Boolean) { autostartAcknowledged = value }
    override fun isOnboardingComplete() = onboardingComplete
    override fun setOnboardingComplete(value: Boolean) { onboardingComplete = value }
    override fun openAccessibilitySettings() { openAccessibilitySettingsCallCount++ }
    override fun openBatteryOptimizationSettings() { openBatteryOptimizationSettingsCallCount++ }
}
```

```kotlin
// NativeBridgeTest.kt
package com.sorayaferreira.vaiviver.data

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test

private class RecordingResult : MethodChannel.Result {
    var success: Any? = null
    var errorCode: String? = null

    override fun success(result: Any?) { success = result }
    override fun error(code: String, message: String?, details: Any?) { errorCode = code }
    override fun notImplemented() { fail("unexpected notImplemented") }
}

class NativeBridgeTest {
    private fun bridge(
        settingsStore: SettingsStore = SettingsStore(InMemoryKeyValueStore()),
        statsStore: StatsStore = StatsStore(InMemoryKeyValueStore()),
        permissionsChecker: FakePermissionsChecker = FakePermissionsChecker()
    ) = NativeBridge(settingsStore, statsStore, permissionsChecker)

    @Test
    fun `getSettings returns the current settings as a map`() {
        val settingsStore = SettingsStore(InMemoryKeyValueStore()).apply {
            setSettings(AppSettings.DEFAULT.copy(scrollLimitMinutes = 5))
        }
        val result = RecordingResult()

        bridge(settingsStore = settingsStore).onMethodCall(MethodCall("getSettings", null), result)

        val map = result.success as Map<*, *>
        assertEquals(5, map["scrollLimitMinutes"])
        assertEquals(true, map["reelsBlockEnabled"])
    }

    @Test
    fun `setSettings persists the given values`() {
        val settingsStore = SettingsStore(InMemoryKeyValueStore())
        val result = RecordingResult()
        val args = mapOf(
            "reelsBlockEnabled" to false,
            "scrollLimitEnabled" to true,
            "scrollLimitMinutes" to 7
        )

        bridge(settingsStore = settingsStore).onMethodCall(MethodCall("setSettings", args), result)

        assertEquals(7, settingsStore.getSettings().scrollLimitMinutes)
        assertEquals(false, settingsStore.getSettings().reelsBlockEnabled)
    }

    @Test
    fun `getPermissionStatus reflects the permissions checker`() {
        val checker = FakePermissionsChecker(accessibilityEnabled = true, batteryOptimizationIgnored = false)
        val result = RecordingResult()

        bridge(permissionsChecker = checker).onMethodCall(MethodCall("getPermissionStatus", null), result)

        val map = result.success as Map<*, *>
        assertEquals(true, map["accessibilityEnabled"])
        assertEquals(false, map["batteryOptimizationIgnored"])
    }

    @Test
    fun `unknown method calls notImplemented`() {
        var notImplementedCalled = false
        val result = object : MethodChannel.Result {
            override fun success(result: Any?) = fail("unexpected success")
            override fun error(code: String, message: String?, details: Any?) = fail("unexpected error")
            override fun notImplemented() { notImplementedCalled = true }
        }

        bridge().onMethodCall(MethodCall("somethingElse", null), result)

        assertEquals(true, notImplementedCalled)
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.data.NativeBridgeTest"`
Expected: FAIL — `NativeBridge`/`PermissionsChecker` unresolved.

- [ ] **Step 3: Create the `PermissionsChecker` interface and real implementation**

```kotlin
// PermissionsChecker.kt
package com.sorayaferreira.vaiviver.data

interface PermissionsChecker {
    fun isAccessibilityServiceEnabled(): Boolean
    fun isIgnoringBatteryOptimizations(): Boolean
    fun isAutostartAcknowledged(): Boolean
    fun setAutostartAcknowledged(value: Boolean)
    fun isOnboardingComplete(): Boolean
    fun setOnboardingComplete(value: Boolean)
    fun openAccessibilitySettings()
    fun openBatteryOptimizationSettings()
}
```

```kotlin
// AndroidPermissionsChecker.kt
package com.sorayaferreira.vaiviver.data

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import com.sorayaferreira.vaiviver.VaiViverAccessibilityService

class AndroidPermissionsChecker(
    private val context: Context,
    private val keyValueStore: KeyValueStore
) : PermissionsChecker {

    override fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "${context.packageName}/${VaiViverAccessibilityService::class.java.name}"
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(":").any { it.equals(expected, ignoreCase = true) }
    }

    override fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    override fun isAutostartAcknowledged(): Boolean = keyValueStore.getBoolean(KEY_AUTOSTART_ACK, false)

    override fun setAutostartAcknowledged(value: Boolean) {
        keyValueStore.putBoolean(KEY_AUTOSTART_ACK, value)
    }

    override fun isOnboardingComplete(): Boolean = keyValueStore.getBoolean(KEY_ONBOARDING_COMPLETE, false)

    override fun setOnboardingComplete(value: Boolean) {
        keyValueStore.putBoolean(KEY_ONBOARDING_COMPLETE, value)
    }

    override fun openAccessibilitySettings() {
        context.startActivity(
            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    override fun openBatteryOptimizationSettings() {
        context.startActivity(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:${context.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    companion object {
        private const val KEY_AUTOSTART_ACK = "autostart_acknowledged"
        private const val KEY_ONBOARDING_COMPLETE = "onboarding_complete"
    }
}
```

`AndroidPermissionsChecker` itself is not unit tested (Android-framework-bound);
covered manually in Task 18.

- [ ] **Step 4: Implement `NativeBridge`**

```kotlin
package com.sorayaferreira.vaiviver.data

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridge(
    private val settingsStore: SettingsStore,
    private val statsStore: StatsStore,
    private val permissionsChecker: PermissionsChecker
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSettings" -> {
                val s = settingsStore.getSettings()
                result.success(
                    mapOf(
                        "reelsBlockEnabled" to s.reelsBlockEnabled,
                        "scrollLimitEnabled" to s.scrollLimitEnabled,
                        "scrollLimitMinutes" to s.scrollLimitMinutes
                    )
                )
            }
            "setSettings" -> {
                val args = call.arguments as Map<*, *>
                settingsStore.setSettings(
                    AppSettings(
                        reelsBlockEnabled = args["reelsBlockEnabled"] as Boolean,
                        scrollLimitEnabled = args["scrollLimitEnabled"] as Boolean,
                        scrollLimitMinutes = (args["scrollLimitMinutes"] as Number).toInt()
                    )
                )
                result.success(null)
            }
            "getTodayStats" -> {
                val stats = statsStore.getToday()
                result.success(
                    mapOf(
                        "reelsBlockedCount" to stats.reelsBlockedCount,
                        "scrollSecondsSaved" to stats.scrollSecondsSaved
                    )
                )
            }
            "getPermissionStatus" -> {
                result.success(
                    mapOf(
                        "accessibilityEnabled" to permissionsChecker.isAccessibilityServiceEnabled(),
                        "batteryOptimizationIgnored" to permissionsChecker.isIgnoringBatteryOptimizations(),
                        "autostartAcknowledged" to permissionsChecker.isAutostartAcknowledged()
                    )
                )
            }
            "setAutostartAcknowledged" -> {
                val args = call.arguments as Map<*, *>
                permissionsChecker.setAutostartAcknowledged(args["value"] as Boolean)
                result.success(null)
            }
            "openAccessibilitySettings" -> {
                permissionsChecker.openAccessibilitySettings()
                result.success(null)
            }
            "openBatteryOptimizationSettings" -> {
                permissionsChecker.openBatteryOptimizationSettings()
                result.success(null)
            }
            "getOnboardingComplete" -> result.success(permissionsChecker.isOnboardingComplete())
            "setOnboardingComplete" -> {
                val args = call.arguments as Map<*, *>
                permissionsChecker.setOnboardingComplete(args["value"] as Boolean)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.sorayaferreira.vaiviver.data.NativeBridgeTest"`
Expected: PASS

- [ ] **Step 6: Wire it into `MainActivity`**

```kotlin
package com.sorayaferreira.vaiviver

import com.sorayaferreira.vaiviver.data.AndroidPermissionsChecker
import com.sorayaferreira.vaiviver.data.NativeBridge
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.SharedPreferencesKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        val bridge = NativeBridge(
            settingsStore = SettingsStore(keyValueStore),
            statsStore = StatsStore(keyValueStore),
            permissionsChecker = AndroidPermissionsChecker(applicationContext, keyValueStore)
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler(bridge)
    }

    companion object {
        private const val CHANNEL_NAME = "com.sorayaferreira.vaiviver/native"
    }
}
```

- [ ] **Step 7: Confirm the Android module still compiles**

Run: `cd android && ./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 8: Stage the changes (do not commit)**

```bash
git add android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/PermissionsChecker.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/AndroidPermissionsChecker.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/data/NativeBridge.kt \
        android/app/src/main/kotlin/com/sorayaferreira/vaiviver/MainActivity.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/FakePermissionsChecker.kt \
        android/app/src/test/kotlin/com/sorayaferreira/vaiviver/data/NativeBridgeTest.kt
git status
```

---

### Task 8: Dart domain models and repository interfaces

**Files:**
- Create: `lib/domain/models/app_settings.dart`, `daily_stats.dart`, `permission_status.dart`
- Create: `lib/domain/repositories/settings_repository.dart`, `stats_repository.dart`, `permissions_repository.dart`

**Interfaces:**
- Produces: `AppSettings` (`reelsBlockEnabled`, `scrollLimitEnabled`,
  `scrollLimitMinutes`, `copyWith(...)`, `static const defaults`); `DailyStats`
  (`reelsBlockedCount`, `scrollSecondsSaved`, `static const empty`);
  `PermissionStatus` (`accessibilityEnabled`, `batteryOptimizationIgnored`,
  `autostartAcknowledged`, `bool get allGranted`); abstract `SettingsRepository`
  (`Future<AppSettings> getSettings()`, `Future<void> saveSettings(AppSettings)`);
  abstract `StatsRepository` (`Future<DailyStats> getTodayStats()`); abstract
  `PermissionsRepository` (`Future<PermissionStatus> getStatus()`,
  `Future<void> setAutostartAcknowledged(bool)`,
  `Future<void> openAccessibilitySettings()`,
  `Future<void> openBatteryOptimizationSettings()`,
  `Future<bool> isOnboardingComplete()`,
  `Future<void> setOnboardingComplete(bool)`).

Pure Dart, no Flutter/platform dependency — this is what every later Dart task
builds on.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/app_settings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/app_settings.dart';

void main() {
  test('copyWith overrides only the given fields', () {
    const original = AppSettings.defaults;

    final updated = original.copyWith(scrollLimitMinutes: 5);

    expect(updated.scrollLimitMinutes, 5);
    expect(updated.reelsBlockEnabled, original.reelsBlockEnabled);
    expect(updated.scrollLimitEnabled, original.scrollLimitEnabled);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/domain/app_settings_test.dart`
Expected: FAIL — `package:vaiviver/domain/models/app_settings.dart` not found.

- [ ] **Step 3: Create the models**

```dart
// lib/domain/models/app_settings.dart
class AppSettings {
  const AppSettings({
    required this.reelsBlockEnabled,
    required this.scrollLimitEnabled,
    required this.scrollLimitMinutes,
  });

  final bool reelsBlockEnabled;
  final bool scrollLimitEnabled;
  final int scrollLimitMinutes;

  static const defaults = AppSettings(
    reelsBlockEnabled: true,
    scrollLimitEnabled: true,
    scrollLimitMinutes: 2,
  );

  AppSettings copyWith({
    bool? reelsBlockEnabled,
    bool? scrollLimitEnabled,
    int? scrollLimitMinutes,
  }) {
    return AppSettings(
      reelsBlockEnabled: reelsBlockEnabled ?? this.reelsBlockEnabled,
      scrollLimitEnabled: scrollLimitEnabled ?? this.scrollLimitEnabled,
      scrollLimitMinutes: scrollLimitMinutes ?? this.scrollLimitMinutes,
    );
  }
}
```

```dart
// lib/domain/models/daily_stats.dart
class DailyStats {
  const DailyStats({required this.reelsBlockedCount, required this.scrollSecondsSaved});

  final int reelsBlockedCount;
  final int scrollSecondsSaved;

  static const empty = DailyStats(reelsBlockedCount: 0, scrollSecondsSaved: 0);
}
```

```dart
// lib/domain/models/permission_status.dart
class PermissionStatus {
  const PermissionStatus({
    required this.accessibilityEnabled,
    required this.batteryOptimizationIgnored,
    required this.autostartAcknowledged,
  });

  final bool accessibilityEnabled;
  final bool batteryOptimizationIgnored;
  final bool autostartAcknowledged;

  bool get allGranted =>
      accessibilityEnabled && batteryOptimizationIgnored && autostartAcknowledged;
}
```

- [ ] **Step 4: Create the repository interfaces**

```dart
// lib/domain/repositories/settings_repository.dart
import '../models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}
```

```dart
// lib/domain/repositories/stats_repository.dart
import '../models/daily_stats.dart';

abstract class StatsRepository {
  Future<DailyStats> getTodayStats();
}
```

```dart
// lib/domain/repositories/permissions_repository.dart
import '../models/permission_status.dart';

abstract class PermissionsRepository {
  Future<PermissionStatus> getStatus();
  Future<void> setAutostartAcknowledged(bool value);
  Future<void> openAccessibilitySettings();
  Future<void> openBatteryOptimizationSettings();
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/domain/app_settings_test.dart`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add lib/domain test/domain/app_settings_test.dart
git status
```

---

### Task 9: Native channel wrapper and MethodChannel repository implementations

**Files:**
- Create: `lib/core/native_bridge.dart`
- Create: `lib/data/method_channel_settings_repository.dart`, `method_channel_stats_repository.dart`, `method_channel_permissions_repository.dart`
- Test: `test/data/method_channel_settings_repository_test.dart`, `method_channel_stats_repository_test.dart`, `method_channel_permissions_repository_test.dart`

**Interfaces:**
- Consumes: `AppSettings`, `DailyStats`, `PermissionStatus`,
  `SettingsRepository`, `StatsRepository`, `PermissionsRepository` (Task 8).
  Method names must exactly match Task 7's `NativeBridge`: `getSettings`,
  `setSettings`, `getTodayStats`, `getPermissionStatus`,
  `setAutostartAcknowledged`, `openAccessibilitySettings`,
  `openBatteryOptimizationSettings`, `getOnboardingComplete`,
  `setOnboardingComplete`.
- Produces: `NativeBridge` (wraps a single `MethodChannel` on
  `com.sorayaferreira.vaiviver/native`); `MethodChannelSettingsRepository`,
  `MethodChannelStatsRepository`, `MethodChannelPermissionsRepository`
  implementing the Task 8 interfaces.

**Review Focus covered here:** a failed/missing platform response must surface
as a catchable Dart error (a `PlatformException` from `invokeMethod` propagates
naturally since these methods aren't wrapped in try/catch — that's intentional;
Task 13 is where the ViewModel/UI turns it into a rendered error state).

- [ ] **Step 1: Write the failing test**

```dart
// test/data/method_channel_settings_repository_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/native_bridge.dart';
import 'package:vaiviver/data/method_channel_settings_repository.dart';
import 'package:vaiviver/domain/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.sorayaferreira.vaiviver/native');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getSettings calls the native method and parses the response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getSettings');
      return {
        'reelsBlockEnabled': true,
        'scrollLimitEnabled': false,
        'scrollLimitMinutes': 3,
      };
    });
    final repository = MethodChannelSettingsRepository(NativeBridge(channel: channel));

    final settings = await repository.getSettings();

    expect(settings.reelsBlockEnabled, true);
    expect(settings.scrollLimitEnabled, false);
    expect(settings.scrollLimitMinutes, 3);
  });

  test('saveSettings sends the settings as arguments', () async {
    Map<Object?, Object?>? receivedArgs;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      receivedArgs = call.arguments as Map<Object?, Object?>;
      return null;
    });
    final repository = MethodChannelSettingsRepository(NativeBridge(channel: channel));

    await repository.saveSettings(
      const AppSettings(reelsBlockEnabled: false, scrollLimitEnabled: true, scrollLimitMinutes: 9),
    );

    expect(receivedArgs!['scrollLimitMinutes'], 9);
    expect(receivedArgs!['reelsBlockEnabled'], false);
  });

  test('a platform failure propagates as a PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    final repository = MethodChannelSettingsRepository(NativeBridge(channel: channel));

    expect(() => repository.getSettings(), throwsA(isA<PlatformException>()));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/method_channel_settings_repository_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Create the native bridge wrapper**

```dart
// lib/core/native_bridge.dart
import 'package:flutter/services.dart';

class NativeBridge {
  NativeBridge({MethodChannel? channel})
      : channel = channel ?? const MethodChannel('com.sorayaferreira.vaiviver/native');

  final MethodChannel channel;
}
```

- [ ] **Step 4: Implement the three repositories**

```dart
// lib/data/method_channel_settings_repository.dart
import '../core/native_bridge.dart';
import '../domain/models/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class MethodChannelSettingsRepository implements SettingsRepository {
  MethodChannelSettingsRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<AppSettings> getSettings() async {
    final map = await _bridge.channel.invokeMapMethod<String, Object?>('getSettings');
    return AppSettings(
      reelsBlockEnabled: map!['reelsBlockEnabled'] as bool,
      scrollLimitEnabled: map['scrollLimitEnabled'] as bool,
      scrollLimitMinutes: map['scrollLimitMinutes'] as int,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _bridge.channel.invokeMethod('setSettings', {
      'reelsBlockEnabled': settings.reelsBlockEnabled,
      'scrollLimitEnabled': settings.scrollLimitEnabled,
      'scrollLimitMinutes': settings.scrollLimitMinutes,
    });
  }
}
```

```dart
// lib/data/method_channel_stats_repository.dart
import '../core/native_bridge.dart';
import '../domain/models/daily_stats.dart';
import '../domain/repositories/stats_repository.dart';

class MethodChannelStatsRepository implements StatsRepository {
  MethodChannelStatsRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<DailyStats> getTodayStats() async {
    final map = await _bridge.channel.invokeMapMethod<String, Object?>('getTodayStats');
    return DailyStats(
      reelsBlockedCount: map!['reelsBlockedCount'] as int,
      scrollSecondsSaved: map['scrollSecondsSaved'] as int,
    );
  }
}
```

```dart
// lib/data/method_channel_permissions_repository.dart
import '../core/native_bridge.dart';
import '../domain/models/permission_status.dart';
import '../domain/repositories/permissions_repository.dart';

class MethodChannelPermissionsRepository implements PermissionsRepository {
  MethodChannelPermissionsRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<PermissionStatus> getStatus() async {
    final map = await _bridge.channel.invokeMapMethod<String, Object?>('getPermissionStatus');
    return PermissionStatus(
      accessibilityEnabled: map!['accessibilityEnabled'] as bool,
      batteryOptimizationIgnored: map['batteryOptimizationIgnored'] as bool,
      autostartAcknowledged: map['autostartAcknowledged'] as bool,
    );
  }

  @override
  Future<void> setAutostartAcknowledged(bool value) {
    return _bridge.channel.invokeMethod('setAutostartAcknowledged', {'value': value});
  }

  @override
  Future<void> openAccessibilitySettings() {
    return _bridge.channel.invokeMethod('openAccessibilitySettings');
  }

  @override
  Future<void> openBatteryOptimizationSettings() {
    return _bridge.channel.invokeMethod('openBatteryOptimizationSettings');
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final value = await _bridge.channel.invokeMethod<bool>('getOnboardingComplete');
    return value ?? false;
  }

  @override
  Future<void> setOnboardingComplete(bool value) {
    return _bridge.channel.invokeMethod('setOnboardingComplete', {'value': value});
  }
}
```

- [ ] **Step 5: Run the test to verify it passes, then write and run the
  equivalent tests for stats and permissions repositories** (same
  `setMockMethodCallHandler` pattern as step 1, one test file each, covering the
  success path and argument marshalling for every method listed above)

Run: `flutter test test/data/`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add lib/core/native_bridge.dart lib/data test/data
git status
```

---

### Task 10: Fake repositories for testing

**Files:**
- Create: `test/fakes/fake_settings_repository.dart`, `fake_stats_repository.dart`, `fake_permissions_repository.dart`

**Interfaces:**
- Consumes: `SettingsRepository`, `StatsRepository`, `PermissionsRepository`,
  `AppSettings`, `DailyStats`, `PermissionStatus` (Task 8).
- Produces: `FakeSettingsRepository` (constructor takes optional initial
  `AppSettings`, exposes `saveCallCount`), `FakeStatsRepository` (constructor
  takes `DailyStats`), `FakePermissionsRepository` (constructor takes
  `PermissionStatus` + `onboardingComplete`, exposes
  `openAccessibilitySettingsCallCount`, `openBatteryOptimizationSettingsCallCount`,
  `setOnboardingCompleteCallCount`) — every later ViewModel test (Tasks 11-12) and
  widget test (Tasks 13-17) is built on these.

This task has no separate test of its own — the fakes are exercised directly by
the tasks that consume them, which is the testable deliverable.

- [ ] **Step 1: Create the fakes**

```dart
// test/fakes/fake_settings_repository.dart
import 'package:vaiviver/domain/models/app_settings.dart';
import 'package:vaiviver/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppSettings? initial]) : _settings = initial ?? AppSettings.defaults;

  AppSettings _settings;
  int saveCallCount = 0;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    saveCallCount++;
  }
}
```

```dart
// test/fakes/fake_stats_repository.dart
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/domain/repositories/stats_repository.dart';

class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository([this.stats = DailyStats.empty]);

  DailyStats stats;

  @override
  Future<DailyStats> getTodayStats() async => stats;
}
```

```dart
// test/fakes/fake_permissions_repository.dart
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/domain/repositories/permissions_repository.dart';

class FakePermissionsRepository implements PermissionsRepository {
  FakePermissionsRepository({
    this.status = const PermissionStatus(
      accessibilityEnabled: true,
      batteryOptimizationIgnored: true,
      autostartAcknowledged: true,
    ),
    bool onboardingComplete = true,
  }) : _onboardingComplete = onboardingComplete;

  PermissionStatus status;
  bool _onboardingComplete;
  int openAccessibilitySettingsCallCount = 0;
  int openBatteryOptimizationSettingsCallCount = 0;
  int setOnboardingCompleteCallCount = 0;

  @override
  Future<PermissionStatus> getStatus() async => status;

  @override
  Future<void> setAutostartAcknowledged(bool value) async {
    status = PermissionStatus(
      accessibilityEnabled: status.accessibilityEnabled,
      batteryOptimizationIgnored: status.batteryOptimizationIgnored,
      autostartAcknowledged: value,
    );
  }

  @override
  Future<void> openAccessibilitySettings() async {
    openAccessibilitySettingsCallCount++;
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    openBatteryOptimizationSettingsCallCount++;
  }

  @override
  Future<bool> isOnboardingComplete() async => _onboardingComplete;

  @override
  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    setOnboardingCompleteCallCount++;
  }
}
```

- [ ] **Step 2: Confirm the project still analyzes cleanly**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 3: Stage the changes (do not commit)**

```bash
git add test/fakes
git status
```

---

### Task 11: Settings and Stats ViewModels (Riverpod)

**Files:**
- Create: `lib/features/settings/settings_view_model.dart`, `lib/features/stats/stats_view_model.dart`
- Test: `test/features/settings/settings_view_model_test.dart`, `test/features/stats/stats_view_model_test.dart`

**Interfaces:**
- Consumes: `AppSettings`, `DailyStats`, `SettingsRepository`, `StatsRepository`
  (Task 8); `MethodChannelSettingsRepository`, `MethodChannelStatsRepository`,
  `NativeBridge` (Task 9, as the real default binding); `FakeSettingsRepository`,
  `FakeStatsRepository` (Task 10, for tests).
- Produces: `settingsRepositoryProvider` (`Provider<SettingsRepository>`, default
  bound to `MethodChannelSettingsRepository(NativeBridge())`),
  `settingsViewModelProvider` (`AsyncNotifierProvider<SettingsViewModel,
  AppSettings>`) with `SettingsViewModel` exposing
  `setReelsBlockEnabled(bool)`, `setScrollLimitEnabled(bool)`,
  `setScrollLimitMinutes(int)`; `statsRepositoryProvider`
  (`Provider<StatsRepository>`), `statsViewModelProvider`
  (`AsyncNotifierProvider<StatsViewModel, DailyStats>`) with `StatsViewModel`
  exposing `refresh()` — **Task 13's Home screen watches both providers and
  calls `refresh()` on app resume.**

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/settings/settings_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';

import '../../fakes/fake_settings_repository.dart';

void main() {
  test('setScrollLimitMinutes saves and updates state', () async {
    final fakeRepo = FakeSettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    await container.read(settingsViewModelProvider.notifier).setScrollLimitMinutes(7);

    expect(container.read(settingsViewModelProvider).value!.scrollLimitMinutes, 7);
    expect(fakeRepo.saveCallCount, 1);
  });

  test('setReelsBlockEnabled saves and updates state', () async {
    final fakeRepo = FakeSettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    await container.read(settingsViewModelProvider.notifier).setReelsBlockEnabled(false);

    expect(container.read(settingsViewModelProvider).value!.reelsBlockEnabled, false);
  });
}
```

```dart
// test/features/stats/stats_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_stats_repository.dart';

void main() {
  test('refresh re-reads stats from the repository', () async {
    final fakeRepo = FakeStatsRepository(const DailyStats(reelsBlockedCount: 1, scrollSecondsSaved: 30));
    final container = ProviderContainer(
      overrides: [statsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(statsViewModelProvider.future);
    fakeRepo.stats = const DailyStats(reelsBlockedCount: 3, scrollSecondsSaved: 90);
    await container.read(statsViewModelProvider.notifier).refresh();

    expect(container.read(statsViewModelProvider).value!.reelsBlockedCount, 3);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/settings/settings_view_model_test.dart test/features/stats/stats_view_model_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement `SettingsViewModel`**

```dart
// lib/features/settings/settings_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_bridge.dart';
import '../../data/method_channel_settings_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MethodChannelSettingsRepository(NativeBridge());
});

class SettingsViewModel extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).getSettings();
  }

  Future<void> setReelsBlockEnabled(bool value) => _update((s) => s.copyWith(reelsBlockEnabled: value));
  Future<void> setScrollLimitEnabled(bool value) => _update((s) => s.copyWith(scrollLimitEnabled: value));
  Future<void> setScrollLimitMinutes(int minutes) => _update((s) => s.copyWith(scrollLimitMinutes: minutes));

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    final current = state.value;
    if (current == null) return;
    final updated = transform(current);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    state = AsyncData(updated);
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, AppSettings>(SettingsViewModel.new);
```

- [ ] **Step 4: Implement `StatsViewModel`**

```dart
// lib/features/stats/stats_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_bridge.dart';
import '../../data/method_channel_stats_repository.dart';
import '../../domain/models/daily_stats.dart';
import '../../domain/repositories/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return MethodChannelStatsRepository(NativeBridge());
});

class StatsViewModel extends AsyncNotifier<DailyStats> {
  @override
  Future<DailyStats> build() {
    return ref.watch(statsRepositoryProvider).getTodayStats();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(statsRepositoryProvider).getTodayStats());
  }
}

final statsViewModelProvider =
    AsyncNotifierProvider<StatsViewModel, DailyStats>(StatsViewModel.new);
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/settings/settings_view_model_test.dart test/features/stats/stats_view_model_test.dart`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add lib/features/settings/settings_view_model.dart lib/features/stats/stats_view_model.dart \
        test/features/settings/settings_view_model_test.dart test/features/stats/stats_view_model_test.dart
git status
```

---

### Task 12: Permissions ViewModel (Riverpod)

**Files:**
- Create: `lib/features/permissions/permissions_view_model.dart`
- Test: `test/features/permissions/permissions_view_model_test.dart`

**Interfaces:**
- Consumes: `PermissionStatus`, `PermissionsRepository` (Task 8);
  `MethodChannelPermissionsRepository`, `NativeBridge` (Task 9);
  `FakePermissionsRepository` (Task 10).
- Produces: `permissionsRepositoryProvider` (`Provider<PermissionsRepository>`),
  `permissionsViewModelProvider` (`AsyncNotifierProvider<PermissionsViewModel,
  PermissionStatus>`) with `PermissionsViewModel` exposing `refresh()`,
  `acknowledgeAutostart()`, `openAccessibilitySettings()`,
  `openBatteryOptimizationSettings()` — **Task 13's Home screen and Task 15's
  Permissions screen both depend on this.**

- [ ] **Step 1: Write the failing test**

```dart
// test/features/permissions/permissions_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';

void main() {
  test('acknowledgeAutostart persists and refreshes status', () async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(permissionsViewModelProvider.future);
    await container.read(permissionsViewModelProvider.notifier).acknowledgeAutostart();

    expect(container.read(permissionsViewModelProvider).value!.autostartAcknowledged, true);
  });

  test('openAccessibilitySettings delegates to the repository', () async {
    final fakeRepo = FakePermissionsRepository();
    final container = ProviderContainer(
      overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(permissionsViewModelProvider.future);
    await container.read(permissionsViewModelProvider.notifier).openAccessibilitySettings();

    expect(fakeRepo.openAccessibilitySettingsCallCount, 1);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/permissions/permissions_view_model_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement `PermissionsViewModel`**

```dart
// lib/features/permissions/permissions_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_bridge.dart';
import '../../data/method_channel_permissions_repository.dart';
import '../../domain/models/permission_status.dart';
import '../../domain/repositories/permissions_repository.dart';

final permissionsRepositoryProvider = Provider<PermissionsRepository>((ref) {
  return MethodChannelPermissionsRepository(NativeBridge());
});

class PermissionsViewModel extends AsyncNotifier<PermissionStatus> {
  @override
  Future<PermissionStatus> build() {
    return ref.watch(permissionsRepositoryProvider).getStatus();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(permissionsRepositoryProvider).getStatus());
  }

  Future<void> acknowledgeAutostart() async {
    await ref.read(permissionsRepositoryProvider).setAutostartAcknowledged(true);
    await refresh();
  }

  Future<void> openAccessibilitySettings() {
    return ref.read(permissionsRepositoryProvider).openAccessibilitySettings();
  }

  Future<void> openBatteryOptimizationSettings() {
    return ref.read(permissionsRepositoryProvider).openBatteryOptimizationSettings();
  }
}

final permissionsViewModelProvider =
    AsyncNotifierProvider<PermissionsViewModel, PermissionStatus>(PermissionsViewModel.new);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/permissions/permissions_view_model_test.dart`
Expected: PASS

- [ ] **Step 5: Stage the changes (do not commit)**

```bash
git add lib/features/permissions/permissions_view_model.dart \
        test/features/permissions/permissions_view_model_test.dart
git status
```

---

### Task 13: Home / Status screen

**Files:**
- Create: `lib/features/home/home_screen.dart`
- Test: `test/features/home/home_screen_test.dart`

**Interfaces:**
- Consumes: `settingsViewModelProvider` is not needed here; `statsViewModelProvider`,
  `permissionsViewModelProvider` (Tasks 11-12); `DailyStats`, `PermissionStatus`
  (Task 8); `FakeStatsRepository`, `FakePermissionsRepository` (Task 10).
- Produces: `HomeScreen` widget. Navigates to `'/settings'` and `'/permissions'`
  by **named route** (not by importing `SettingsScreen`/`PermissionsScreen`
  directly) — this is what lets this task compile before Tasks 14-15 exist. Those
  routes are registered in Task 17's `main.dart`.

**Review Focus covered here:** stale permission status after the app is
backgrounded and resumed (e.g. the user revoked Accessibility in system
Settings) — `HomeScreen` re-checks both providers on
`AppLifecycleState.resumed`, not only once at startup; and a repository/channel
error renders as visible error text instead of a blank or frozen screen.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/home/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/home/home_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../fakes/fake_stats_repository.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
      routes: {
        '/settings': (_) => const Scaffold(body: Text('settings-stub')),
        '/permissions': (_) => const Scaffold(body: Text('permissions-stub')),
      },
    ),
  );
}

void main() {
  testWidgets('shows today\'s stats and a granted status card', (tester) async {
    await tester.pumpWidget(_wrap(
      const HomeScreen(),
      overrides: [
        statsRepositoryProvider.overrideWithValue(
          FakeStatsRepository(const DailyStats(reelsBlockedCount: 4, scrollSecondsSaved: 300)),
        ),
        permissionsRepositoryProvider.overrideWithValue(FakePermissionsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reels bloqueados hoje: 4'), findsOneWidget);
    expect(find.text('Minutos de scroll evitados hoje: 5 min'), findsOneWidget);
    expect(find.text('Proteções ativas'), findsOneWidget);
  });

  testWidgets('shows an action-needed card when a permission is missing', (tester) async {
    await tester.pumpWidget(_wrap(
      const HomeScreen(),
      overrides: [
        statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
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
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ação necessária'), findsOneWidget);
  });

  testWidgets('tapping the status card navigates to /permissions', (tester) async {
    await tester.pumpWidget(_wrap(
      const HomeScreen(),
      overrides: [
        statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        permissionsRepositoryProvider.overrideWithValue(FakePermissionsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proteções ativas'));
    await tester.pumpAndSettle();

    expect(find.text('permissions-stub'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/home/home_screen_test.dart`
Expected: FAIL — `HomeScreen` doesn't exist.

- [ ] **Step 3: Implement `HomeScreen`**

```dart
// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/daily_stats.dart';
import '../../domain/models/permission_status.dart';
import '../permissions/permissions_view_model.dart';
import '../stats/stats_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsViewModelProvider.notifier).refresh();
      ref.read(statsViewModelProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsViewModelProvider);
    final stats = ref.watch(statsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VaiViver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          permissions.when(
            data: (status) => _PermissionsStatusCard(status: status),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Erro ao carregar permissões: $err'),
          ),
          const SizedBox(height: 16),
          stats.when(
            data: (data) => _StatsCard(stats: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Erro ao carregar estatísticas: $err'),
          ),
        ],
      ),
    );
  }
}

class _PermissionsStatusCard extends StatelessWidget {
  const _PermissionsStatusCard({required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final allGranted = status.allGranted;
    return Card(
      color: allGranted ? Colors.green.shade50 : Colors.orange.shade50,
      child: ListTile(
        leading: Icon(
          allGranted ? Icons.check_circle : Icons.warning,
          color: allGranted ? Colors.green : Colors.orange,
        ),
        title: Text(allGranted ? 'Proteções ativas' : 'Ação necessária'),
        subtitle: allGranted ? null : const Text('Verifique as permissões pendentes'),
        onTap: () => Navigator.of(context).pushNamed('/permissions'),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    final minutesSaved = (stats.scrollSecondsSaved / 60).floor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reels bloqueados hoje: ${stats.reelsBlockedCount}'),
            Text('Minutos de scroll evitados hoje: $minutesSaved min'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/home/home_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Stage the changes (do not commit)**

```bash
git add lib/features/home/home_screen.dart test/features/home/home_screen_test.dart
git status
```

---

### Task 14: Settings screen

**Files:**
- Create: `lib/features/settings/app_settings_form.dart`, `lib/features/settings/settings_screen.dart`
- Test: `test/features/settings/settings_screen_test.dart`

**Interfaces:**
- Consumes: `settingsViewModelProvider`, `SettingsViewModel` (Task 11);
  `AppSettings` (Task 8); `FakeSettingsRepository` (Task 10).
- Produces: `AppSettingsForm` widget (the two toggles + minutes stepper, reused
  as-is by Task 16's onboarding initial-config step) and `SettingsScreen`, which
  wraps it plus a link to `'/permissions'`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/settings/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/settings/settings_screen.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';

import '../../fakes/fake_settings_repository.dart';

void main() {
  testWidgets('toggling reels-block switch saves through the repository', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: SettingsScreen(),
          routes: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reels-block-switch')));
    await tester.pumpAndSettle();

    expect(fakeRepo.saveCallCount, 1);
  });

  testWidgets('changing the minutes stepper saves the new value', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scroll-limit-increment')));
    await tester.pumpAndSettle();

    expect((await fakeRepo.getSettings()).scrollLimitMinutes, 3);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement the reusable form**

```dart
// lib/features/settings/app_settings_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_view_model.dart';

class AppSettingsForm extends ConsumerWidget {
  const AppSettingsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsViewModelProvider);

    return settingsAsync.when(
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('reels-block-switch'),
            title: const Text('Bloquear aba Reels'),
            value: settings.reelsBlockEnabled,
            onChanged: (value) =>
                ref.read(settingsViewModelProvider.notifier).setReelsBlockEnabled(value),
          ),
          SwitchListTile(
            key: const Key('scroll-limit-switch'),
            title: const Text('Limite de scroll no Feed'),
            value: settings.scrollLimitEnabled,
            onChanged: (value) =>
                ref.read(settingsViewModelProvider.notifier).setScrollLimitEnabled(value),
          ),
          ListTile(
            title: const Text('Limite de scroll (minutos)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('scroll-limit-decrement'),
                  icon: const Icon(Icons.remove),
                  onPressed: settings.scrollLimitEnabled && settings.scrollLimitMinutes > 1
                      ? () => ref
                          .read(settingsViewModelProvider.notifier)
                          .setScrollLimitMinutes(settings.scrollLimitMinutes - 1)
                      : null,
                ),
                Text('${settings.scrollLimitMinutes}'),
                IconButton(
                  key: const Key('scroll-limit-increment'),
                  icon: const Icon(Icons.add),
                  onPressed: settings.scrollLimitEnabled
                      ? () => ref
                          .read(settingsViewModelProvider.notifier)
                          .setScrollLimitMinutes(settings.scrollLimitMinutes + 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Erro ao carregar configurações: $err'),
    );
  }
}
```

- [ ] **Step 4: Implement `SettingsScreen`**

```dart
// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';

import 'app_settings_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSettingsForm(),
          const Divider(height: 32),
          ListTile(
            title: const Text('Verificar permissões'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/permissions'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add lib/features/settings/app_settings_form.dart lib/features/settings/settings_screen.dart \
        test/features/settings/settings_screen_test.dart
git status
```

---

### Task 15: Permissions status screen

**Files:**
- Create: `lib/features/permissions/accessibility_status_tile.dart`, `battery_optimization_status_tile.dart`, `autostart_ack_tile.dart`, `permissions_screen.dart`
- Test: `test/features/permissions/permissions_screen_test.dart`

**Interfaces:**
- Consumes: `permissionsViewModelProvider`, `PermissionsViewModel` (Task 12);
  `PermissionStatus` (Task 8); `FakePermissionsRepository` (Task 10).
- Produces: three reusable step-tile widgets
  (`AccessibilityStatusTile(status: PermissionStatus)`,
  `BatteryOptimizationStatusTile(status: PermissionStatus)`,
  `AutostartAckTile(status: PermissionStatus)` — each a `ConsumerWidget` reading
  the current status from its constructor parameter and dispatching actions via
  `permissionsViewModelProvider.notifier`) and `PermissionsScreen`, which lists
  all three. **Task 16's onboarding wizard reuses these same three tiles as
  full-page steps.**

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/permissions/permissions_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/permissions/permissions_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';

void main() {
  testWidgets('shows granted/pending state for each permission', (tester) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: false,
        autostartAcknowledged: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acessibilidade: ativada'), findsOneWidget);
    expect(find.text('Otimização de bateria: pendente'), findsOneWidget);
  });

  testWidgets('tapping the autostart checkbox acknowledges it', (tester) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('autostart-ack-checkbox')));
    await tester.pumpAndSettle();

    expect(fakeRepo.status.autostartAcknowledged, true);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/permissions/permissions_screen_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement the three tiles**

```dart
// lib/features/permissions/accessibility_status_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permissions_view_model.dart';

class AccessibilityStatusTile extends ConsumerWidget {
  const AccessibilityStatusTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(status.accessibilityEnabled ? Icons.check_circle : Icons.error_outline),
      title: Text('Acessibilidade: ${status.accessibilityEnabled ? "ativada" : "pendente"}'),
      subtitle: const Text('Necessária para detectar Reels e medir a rolagem do Feed'),
      trailing: status.accessibilityEnabled
          ? null
          : TextButton(
              onPressed: () => ref.read(permissionsViewModelProvider.notifier).openAccessibilitySettings(),
              child: const Text('Abrir'),
            ),
    );
  }
}
```

```dart
// lib/features/permissions/battery_optimization_status_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permissions_view_model.dart';

class BatteryOptimizationStatusTile extends ConsumerWidget {
  const BatteryOptimizationStatusTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(status.batteryOptimizationIgnored ? Icons.check_circle : Icons.error_outline),
      title: Text(
        'Otimização de bateria: ${status.batteryOptimizationIgnored ? "isenta" : "pendente"}',
      ),
      subtitle: const Text('Sem isso o Android pode encerrar o VaiViver em segundo plano'),
      trailing: status.batteryOptimizationIgnored
          ? null
          : TextButton(
              onPressed: () =>
                  ref.read(permissionsViewModelProvider.notifier).openBatteryOptimizationSettings(),
              child: const Text('Abrir'),
            ),
    );
  }
}
```

```dart
// lib/features/permissions/autostart_ack_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permissions_view_model.dart';

class AutostartAckTile extends ConsumerWidget {
  const AutostartAckTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      key: const Key('autostart-ack-checkbox'),
      value: status.autostartAcknowledged,
      title: const Text('Autostart (Xiaomi/MIUI) habilitado'),
      subtitle: const Text(
        'Configurações > Apps > Gerenciar apps > VaiViver > Autostart, ou '
        'App Segurança > Permissões > Autostart',
      ),
      onChanged: (value) {
        if (value == true) {
          ref.read(permissionsViewModelProvider.notifier).acknowledgeAutostart();
        }
      },
    );
  }
}
```

- [ ] **Step 4: Implement `PermissionsScreen`**

```dart
// lib/features/permissions/permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accessibility_status_tile.dart';
import 'autostart_ack_tile.dart';
import 'battery_optimization_status_tile.dart';
import 'permissions_view_model.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(permissionsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Status das Permissões')),
      body: statusAsync.when(
        data: (status) => ListView(
          children: [
            AccessibilityStatusTile(status: status),
            BatteryOptimizationStatusTile(status: status),
            AutostartAckTile(status: status),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar permissões: $err')),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/permissions/permissions_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add lib/features/permissions/accessibility_status_tile.dart \
        lib/features/permissions/battery_optimization_status_tile.dart \
        lib/features/permissions/autostart_ack_tile.dart \
        lib/features/permissions/permissions_screen.dart \
        test/features/permissions/permissions_screen_test.dart
git status
```

---

### Task 16: Onboarding flow

**Files:**
- Create: `lib/features/onboarding/onboarding_flow_screen.dart`, `lib/features/onboarding/welcome_step.dart`
- Test: `test/features/onboarding/onboarding_flow_screen_test.dart`

**Interfaces:**
- Consumes: `AccessibilityStatusTile`, `BatteryOptimizationStatusTile`,
  `AutostartAckTile`, `permissionsViewModelProvider` (Task 15/12);
  `AppSettingsForm` (Task 14); `HomeScreen` (Task 13, direct import — this is the
  one place in the app that imports a concrete screen instead of using a named
  route, since it's the terminal step of a flow that only ever runs once);
  `PermissionStatus` (Task 8); `FakePermissionsRepository`,
  `FakeSettingsRepository`, `FakeStatsRepository` (Task 10).
- Produces: `OnboardingFlowScreen` widget — a `PageView` of 6 steps (Welcome,
  Accessibility, Battery, Autostart, Initial config, Done) with "Próximo"/
  "Concluir" navigation, calling `setOnboardingComplete(true)` on the last step
  before replacing the route with `HomeScreen`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/onboarding/onboarding_flow_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/onboarding/onboarding_flow_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_stats_repository.dart';

void main() {
  testWidgets('walks through every step to the Home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(FakePermissionsRepository()),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const MaterialApp(home: OnboardingFlowScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vinda ao VaiViver'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('VaiViver'), findsOneWidget); // HomeScreen's AppBar title
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/onboarding/onboarding_flow_screen_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement the welcome step**

```dart
// lib/features/onboarding/welcome_step.dart
import 'package:flutter/material.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bem-vinda ao VaiViver', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'O VaiViver bloqueia a aba Reels do Instagram e limita quanto tempo '
            'você rola o Feed. Para isso, ele precisa de algumas permissões — '
            'vamos te guiar por cada uma.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onNext, child: const Text('Próximo')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement the wizard**

```dart
// lib/features/onboarding/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_screen.dart';
import '../permissions/accessibility_status_tile.dart';
import '../permissions/autostart_ack_tile.dart';
import '../permissions/battery_optimization_status_tile.dart';
import '../permissions/permissions_view_model.dart';
import '../settings/app_settings_form.dart';
import 'welcome_step.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _controller = PageController();

  void _goNext() {
    _controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  Future<void> _finish() async {
    await ref.read(permissionsRepositoryProvider).setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(permissionsViewModelProvider);

    return Scaffold(
      body: statusAsync.when(
        data: (status) => PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            WelcomeStep(onNext: _goNext),
            _StepScaffold(
              child: AccessibilityStatusTile(status: status),
              onNext: _goNext,
            ),
            _StepScaffold(
              child: BatteryOptimizationStatusTile(status: status),
              onNext: _goNext,
            ),
            _StepScaffold(
              child: AutostartAckTile(status: status),
              onNext: _goNext,
            ),
            _StepScaffold(
              child: const AppSettingsForm(),
              onNext: _finish,
              buttonLabel: 'Concluir',
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.child, required this.onNext, this.buttonLabel = 'Próximo'});

  final Widget child;
  final VoidCallback onNext;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(child: child),
          ElevatedButton(onPressed: onNext, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/onboarding/onboarding_flow_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Stage the changes (do not commit)**

```bash
git add lib/features/onboarding test/features/onboarding
git status
```

---

### Task 17: App wiring (`main.dart`)

**Files:**
- Create: `lib/main.dart` (replaces the Flutter-scaffolded placeholder)
- Test: `test/main_test.dart`
- Delete: `test/widget_test.dart` (the placeholder Flutter scaffolded in Task 1)

**Interfaces:**
- Consumes: `permissionsRepositoryProvider` (Task 12), `HomeScreen` (Task 13),
  `SettingsScreen` (Task 14), `PermissionsScreen` (Task 15),
  `OnboardingFlowScreen` (Task 16); `FakePermissionsRepository`,
  `FakeSettingsRepository`, `FakeStatsRepository` (Task 10).
- Produces: `VaiViverApp` widget (registers `'/settings'` and `'/permissions'`
  named routes), `AppStartupGate` (decides Home vs Onboarding based on
  `onboardingCompleteProvider`), `onboardingCompleteProvider`
  (`FutureProvider<bool>`), `main()` entry point.

- [ ] **Step 1: Write the failing test**

```dart
// test/main_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';
import 'package:vaiviver/main.dart';

import 'fakes/fake_permissions_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_stats_repository.dart';

void main() {
  testWidgets('shows onboarding when it has not been completed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(onboardingComplete: false),
          ),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const VaiViverApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vinda ao VaiViver'), findsOneWidget);
  });

  testWidgets('shows Home when onboarding was already completed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(onboardingComplete: true),
          ),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const VaiViverApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VaiViver'), findsOneWidget);
    expect(find.text('Bem-vinda ao VaiViver'), findsNothing);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/main_test.dart`
Expected: FAIL — `VaiViverApp` doesn't exist yet.

- [ ] **Step 3: Delete the scaffolded placeholder test** (it references a
  counter app that no longer exists)

```bash
rm test/widget_test.dart
```

- [ ] **Step 4: Implement `main.dart`**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'features/permissions/permissions_screen.dart';
import 'features/permissions/permissions_view_model.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: VaiViverApp()));
}

final onboardingCompleteProvider = FutureProvider<bool>((ref) {
  return ref.watch(permissionsRepositoryProvider).isOnboardingComplete();
});

class VaiViverApp extends StatelessWidget {
  const VaiViverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaiViver',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/permissions': (_) => const PermissionsScreen(),
      },
      home: const AppStartupGate(),
    );
  }
}

class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
    return onboardingComplete.when(
      data: (complete) => complete ? const HomeScreen() : const OnboardingFlowScreen(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro: $err'))),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/main_test.dart`
Expected: PASS

- [ ] **Step 6: Run the full Dart test suite**

Run: `flutter test`
Expected: every test across every task, PASS.

- [ ] **Step 7: Run the full Kotlin test suite**

Run: `cd android && ./gradlew :app:testDebugUnitTest`
Expected: every test across every task, PASS.

- [ ] **Step 8: Stage the changes (do not commit)**

```bash
git add lib/main.dart test/main_test.dart
git rm test/widget_test.dart
git status
```

---

### Task 18: Manual end-to-end test checklist

**Files:**
- Create: `docs/manual-test-checklist.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: a checklist document. No automated test — per `docs/design.md`
  section 9, the full device flow (real Instagram, real MIUI battery/autostart
  behavior) cannot be exercised by an automated test and needs a physical pass on
  the Xiaomi/Redmi/Poco device this app targets.

- [ ] **Step 1: Write the checklist**

```markdown
# VaiViver — Roteiro de teste manual

Antes de considerar o MVP pronto, rode este roteiro no aparelho físico
(Xiaomi/Redmi/Poco, Android 13+):

## Calibração dos identificadores do Instagram

1. Instale o Instagram e o VaiViver no aparelho.
2. Abra o Instagram e, com o app "Accessibility Scanner" (ou o Layout Inspector
   do Android Studio conectado ao aparelho), inspecione a aba Reels e a aba Feed
   na barra inferior — anote o `resource-id` e/ou `content-description` reais.
3. Compare com as constantes em `ReelsTabRule.REELS_TAB_VIEW_ID_KEYWORDS` /
   `REELS_TAB_CONTENT_DESCRIPTIONS` e `FeedScrollLimitRule.FEED_TAB_VIEW_ID_KEYWORDS`
   (`android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/`).
   Ajuste as listas se os valores reais forem diferentes.

## Onboarding

4. Instale o VaiViver do zero (ou limpe os dados do app) e abra-o — deve cair na
   tela de boas-vindas.
5. Complete o passo de Acessibilidade: o botão deve abrir a tela de
   Configurações de Acessibilidade do Android; ative o VaiViver lá e volte —
   o app deve reconhecer automaticamente que foi ativado.
6. Complete o passo de Otimização de Bateria: o botão deve abrir o diálogo do
   sistema; conceda a isenção.
7. Complete o passo de Autostart: siga as instruções na tela (Configurações >
   Apps > Gerenciar apps > VaiViver > Autostart, ou App Segurança > Permissões
   > Autostart no MIUI/HyperOS) e marque a caixinha.
8. Configure o limite de scroll (ex: 1 minuto, pra testar mais rápido) e conclua
   — deve cair na tela Home.

## Bloqueio de Reels

9. Abra o Instagram e toque na aba Reels — o VaiViver deve te levar
   imediatamente para a tela inicial do Android.
10. Desative o toggle "Bloquear aba Reels" nas Configurações do VaiViver, volte
    ao Instagram e toque em Reels de novo — agora não deve acontecer nada.

## Limite de scroll

11. Reative "Bloquear aba Reels" (ou deixe como está) e ative "Limite de scroll
    no Feed" com um valor baixo (1 minuto). Abra o Instagram, vá para o Feed e
    role continuamente — ao passar do tempo configurado, o VaiViver deve te
    levar para a tela inicial.
12. Saia do Instagram e volte a abrir — o contador deve ter reiniciado (você
    deve conseguir rolar pelo tempo configurado de novo).
13. Desative "Limite de scroll no Feed" e role o Feed por mais tempo que o
    limite configurado — não deve acontecer nada.

## Robustez

14. Reinicie o aparelho, abra o Instagram sem reabrir o VaiViver antes — no
    MIUI/HyperOS a Acessibilidade pode ter sido desativada automaticamente;
    confirme testando o bloqueio de Reels. Se não funcionar, abra o VaiViver:
    a tela Home deve mostrar "⚠️ Ação necessária".
15. Nas Configurações do Android, desative manualmente a permissão de
    Acessibilidade do VaiViver, volte para o app (sem fechá-lo) — a tela Home
    deve refletir isso na próxima vez que ela ganhar foco, sem precisar reabrir
    o app.
16. Confira as estatísticas do dia na tela Home depois dos testes acima —
    "Reels bloqueados hoje" e "Minutos de scroll evitados hoje" devem refletir
    o que aconteceu.
```

- [ ] **Step 2: Stage the changes (do not commit)**

```bash
git add docs/manual-test-checklist.md
git status
```

---

## Plan Self-Review Notes

- **Spec coverage:** RF01-RF02 → Tasks 5-6; RF03-RF06 → Tasks 4-6; RF07 →
  Task 14/16 (toggles); RF08 → Tasks 13, 15; RF09-RF10 → Tasks 15-17; RF11 →
  Task 6 (content inspection gated to Instagram's package, see updated
  `docs/design.md` §4.1). RNF01-RNF08 → Global Constraints, enforced throughout.
  RL01-RL04 → reflected in Task 6 (Home action), Task 5 (calibration risk),
  Task 18 (MIUI reboot check), and the per-session reset design itself.
- **Placeholder scan:** no TBD/TODO; the only "best effort, needs calibration"
  markers are the Instagram UI matcher constants in Task 5, which are real,
  compilable, runnable code — not placeholders — and Task 18 exists specifically
  to close that loop on the real device.
- **Type consistency:** channel name and all 9 method names are identical across
  Task 7 (Kotlin `NativeBridge`) and Task 9 (Dart repositories); `AppSettings`/
  `DailyStats`/`PermissionStatus` field names match between the Kotlin data
  classes (Task 3) and their Dart counterparts (Task 8) and the map keys passed
  over the channel (Task 7/9).
- **Review Focus:** all five items list the task that owns their test (see the
  Review Focus section above).
