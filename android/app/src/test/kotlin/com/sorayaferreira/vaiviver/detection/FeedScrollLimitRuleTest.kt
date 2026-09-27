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
