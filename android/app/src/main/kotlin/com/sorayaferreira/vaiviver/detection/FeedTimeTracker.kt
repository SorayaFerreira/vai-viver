package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.StatsStore
import java.util.Calendar

/**
 * Adds up today's time with Instagram's Home tab on screen. An interval opens
 * when the tab becomes visible and closes when it stops being visible (another
 * tab, another app, screen off); only closed intervals are written to
 * [StatsStore], the open one is added on read. Time before today's midnight is
 * dropped: the limit is per calendar day.
 */
class FeedTimeTracker(
    private val stats: StatsStore,
    private val clock: () -> Long = System::currentTimeMillis,
    private val startOfDay: (Long) -> Long = ::startOfLocalDay
) {
    private var openSince: Long? = null

    val isCounting: Boolean get() = openSince != null

    fun update(onHomeTab: Boolean) {
        val now = clock()
        val since = openSince
        if (onHomeTab && since == null) {
            openSince = now
        } else if (!onHomeTab && since != null) {
            stats.addFeedMillis(countable(since, now))
            openSince = null
        }
    }

    fun stop() = update(onHomeTab = false)

    fun usedTodayMillis(): Long {
        val now = clock()
        val pending = openSince?.let { countable(it, now) } ?: 0L
        return stats.feedMillisToday() + pending
    }

    private fun countable(since: Long, now: Long): Long = now - maxOf(since, startOfDay(now))
}

fun startOfLocalDay(millis: Long): Long = Calendar.getInstance().apply {
    timeInMillis = millis
    set(Calendar.HOUR_OF_DAY, 0)
    set(Calendar.MINUTE, 0)
    set(Calendar.SECOND, 0)
    set(Calendar.MILLISECOND, 0)
}.timeInMillis
