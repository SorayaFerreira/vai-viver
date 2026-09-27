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
