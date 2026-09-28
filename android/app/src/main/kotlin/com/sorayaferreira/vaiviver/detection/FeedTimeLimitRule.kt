package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.SettingsStore

/**
 * Daily limit on time with Instagram's Home tab open. Time is tracked even with
 * the limit off (the Home screen shows it); blocking needs the limit on. Once
 * over the limit, opening Instagram (which always lands on Home) grants
 * [graceMs] to switch to another tab; returning to Home later blocks at once.
 */
class FeedTimeLimitRule(
    private val settingsStore: SettingsStore,
    private val tracker: FeedTimeTracker,
    private val clock: () -> Long = System::currentTimeMillis,
    private val graceMs: Long = GRACE_MS
) : DetectionRule {
    private var sessionStartedAt: Long? = null

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        val now = clock()
        val sessionStart = sessionStartedAt ?: now.also { sessionStartedAt = it }
        val onHomeTab = HomeTabDetector.isHomeTabSelected(root)
        tracker.update(onHomeTab)

        val settings = settingsStore.getSettings()
        val blocks = onHomeTab &&
            settings.feedLimitEnabled &&
            tracker.usedTodayMillis() >= limitMillis(settings) &&
            now - sessionStart >= graceMs
        return if (blocks) RuleResult.Block(BlockReason.FEED_TIME_LIMIT) else RuleResult.NoAction
    }

    /**
     * When the service should re-read the screen even without new events (the
     * user may just sit on the feed): at the limit, or when the grace ends.
     * Null when nothing can block without a new event.
     */
    fun millisUntilNextCheck(): Long? {
        val settings = settingsStore.getSettings()
        if (!settings.feedLimitEnabled || !tracker.isCounting) return null
        val remaining = limitMillis(settings) - tracker.usedTodayMillis()
        if (remaining > 0) return remaining
        val sessionStart = sessionStartedAt ?: return 0L
        return maxOf(0L, graceMs - (clock() - sessionStart))
    }

    override fun onSessionEnded() {
        tracker.stop()
        sessionStartedAt = null
    }

    private fun limitMillis(settings: AppSettings) = settings.feedLimitMinutes * 60_000L

    companion object {
        const val GRACE_MS = 5_000L
    }
}
