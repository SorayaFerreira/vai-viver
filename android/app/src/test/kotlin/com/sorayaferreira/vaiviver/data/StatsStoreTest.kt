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
