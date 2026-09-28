package com.sorayaferreira.vaiviver.data

data class DailyStats(
    val reelsBlockedCount: Int,
    val feedSecondsToday: Int,
    val feedBlockedCount: Int
) {
    companion object {
        val EMPTY = DailyStats(reelsBlockedCount = 0, feedSecondsToday = 0, feedBlockedCount = 0)
    }
}
