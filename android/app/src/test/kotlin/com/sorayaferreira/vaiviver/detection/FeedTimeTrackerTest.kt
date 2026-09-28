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
