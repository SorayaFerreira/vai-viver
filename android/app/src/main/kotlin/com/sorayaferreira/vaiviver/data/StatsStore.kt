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

    fun addFeedMillis(millis: Long) {
        val key = feedMillisKey(today())
        store.putInt(key, (store.getInt(key, 0) + millis).toInt())
    }

    fun feedMillisToday(): Long = store.getInt(feedMillisKey(today()), 0).toLong()

    fun incrementFeedBlocked() {
        val key = feedBlockedKey(today())
        store.putInt(key, store.getInt(key, 0) + 1)
    }

    fun getToday(): DailyStats {
        val date = today()
        return DailyStats(
            reelsBlockedCount = store.getInt(reelsBlockedKey(date), 0),
            feedSecondsToday = store.getInt(feedMillisKey(date), 0) / 1000,
            feedBlockedCount = store.getInt(feedBlockedKey(date), 0)
        )
    }

    private fun reelsBlockedKey(date: String) = "stats_reels_blocked_$date"
    private fun feedMillisKey(date: String) = "stats_feed_millis_$date"
    private fun feedBlockedKey(date: String) = "stats_feed_blocked_$date"

    companion object {
        fun defaultTodayKey(): String =
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    }
}
