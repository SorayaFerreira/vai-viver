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

    @Test
    fun `keeps separate counters per day`() {
        var date = "2026-09-26"
        val store = StatsStore(InMemoryKeyValueStore(), today = { date })

        store.incrementReelsBlocked()
        store.addFeedMillis(1_000)
        date = "2026-09-27"

        assertEquals(0, store.getToday().reelsBlockedCount)
        assertEquals(0L, store.feedMillisToday())
    }
}
