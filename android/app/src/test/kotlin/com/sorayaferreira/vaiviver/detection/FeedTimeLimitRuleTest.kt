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
