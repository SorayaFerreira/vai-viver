package com.sorayaferreira.vaiviver.data

data class DailyStats(
    val reelsBlockedCount: Int,
    val scrollSecondsSaved: Int
) {
    companion object {
        val EMPTY = DailyStats(reelsBlockedCount = 0, scrollSecondsSaved = 0)
    }
}
