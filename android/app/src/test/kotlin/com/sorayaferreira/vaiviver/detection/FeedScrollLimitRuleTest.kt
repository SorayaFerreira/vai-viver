package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.InMemoryKeyValueStore
import com.sorayaferreira.vaiviver.data.SettingsStore
import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.assertEquals
import org.junit.Test

class FeedScrollLimitRuleTest {
    private val feedRoot = ScreenNode(
        viewId = "feed_tab_container",
        contentDescription = null,
        className = "FrameLayout",
        isSelected = true
    )

    /** Instagram-like bottom nav: every tab button is always present, only one is selected. */
    private fun screenWithBottomNav(feedSelected: Boolean, reelsSelected: Boolean) = ScreenNode(
        viewId = "root",
        contentDescription = null,
        className = "FrameLayout",
        children = listOf(
            ScreenNode(viewId = "content", contentDescription = null, className = "FrameLayout"),
            ScreenNode(
                viewId = "tab_bar",
                contentDescription = null,
                className = "LinearLayout",
                children = listOf(
                    ScreenNode(
                        viewId = "feed_tab",
                        contentDescription = "Home",
                        className = "FrameLayout",
                        isSelected = feedSelected
                    ),
                    ScreenNode(
                        viewId = "clips_tab",
                        contentDescription = "Reels",
                        className = "FrameLayout",
                        isSelected = reelsSelected
                    ),
                    ScreenNode(
                        viewId = "profile_tab",
                        contentDescription = "Profile",
                        className = "FrameLayout"
                    )
                )
            )
        )
    )

    private fun settingsStore(scrollLimitEnabled: Boolean = true, minutes: Int = 2) =
        SettingsStore(InMemoryKeyValueStore()).apply {
            setSettings(AppSettings.DEFAULT.copy(scrollLimitEnabled = scrollLimitEnabled, scrollLimitMinutes = minutes))
        }

    @Test
    fun `blocks once accumulated scroll time exceeds the configured limit`() {
        var now = 0L
        val rule = FeedScrollLimitRule(
            settingsStore(minutes = 1),
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
        val rule = FeedScrollLimitRule(settingsStore(minutes = 1), accumulator)

        repeat(310) {
            now += 200L
            rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }
        rule.onSessionEnded()

        assertEquals(0L, accumulator.accumulatedMillis())
    }

    @Test
    fun `does not count scrolling when the feed button is present but another tab is selected`() {
        var now = 0L
        val rule = FeedScrollLimitRule(
            settingsStore(minutes = 1),
            ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        )
        val onReels = screenWithBottomNav(feedSelected = false, reelsSelected = true)

        var result: RuleResult = RuleResult.NoAction
        repeat(310) {
            now += 200L
            result = rule.evaluate(onReels, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }

        assertEquals(RuleResult.NoAction, result)
    }

    @Test
    fun `blocks when the full bottom nav is present and the feed tab is the selected one`() {
        var now = 0L
        val rule = FeedScrollLimitRule(
            settingsStore(minutes = 1),
            ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        )
        val onFeed = screenWithBottomNav(feedSelected = true, reelsSelected = false)

        var result: RuleResult = RuleResult.NoAction
        repeat(310) {
            now += 200L
            result = rule.evaluate(onFeed, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }

        assertEquals(RuleResult.Block(BlockReason.SCROLL_LIMIT), result)
    }

    @Test
    fun `scroll progress does not carry over across a disable and re-enable cycle`() {
        var now = 0L
        val settings = settingsStore(minutes = 1) // limit = 60_000 ms
        val rule = FeedScrollLimitRule(
            settings,
            ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        )

        // Enabled: 300 events 200ms apart = 299 gaps = 59_800 ms, just under the limit.
        repeat(300) {
            now += 200L
            assertEquals(RuleResult.NoAction, rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED))
        }

        // Disabled: keep scrolling — must neither block nor accumulate.
        settings.setSettings(settings.getSettings().copy(scrollLimitEnabled = false))
        repeat(50) {
            now += 200L
            assertEquals(RuleResult.NoAction, rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED))
        }

        // Re-enabled: a few more continuous ticks. The first re-establishes the timing
        // baseline; the following ones add 200ms each. Had the 59_800 ms survived the
        // disable, the third tick (59_800 + 400 >= 60_000) would block.
        settings.setSettings(settings.getSettings().copy(scrollLimitEnabled = true))
        var result: RuleResult = RuleResult.NoAction
        repeat(3) {
            now += 200L
            result = rule.evaluate(feedRoot, AccessibilityEvent.TYPE_VIEW_SCROLLED)
        }

        assertEquals(RuleResult.NoAction, result)
    }
}
