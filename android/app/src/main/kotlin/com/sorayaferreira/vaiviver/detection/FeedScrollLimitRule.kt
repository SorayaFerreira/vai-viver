package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.StatsStore

class FeedScrollLimitRule(
    private val settingsStore: SettingsStore,
    private val statsStore: StatsStore,
    private val accumulator: ScrollActivityAccumulator = ScrollActivityAccumulator()
) : DetectionRule {

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        val settings = settingsStore.getSettings()
        if (!settings.scrollLimitEnabled) return RuleResult.NoAction

        val onFeedTab = root.findFirst { node ->
            FEED_TAB_VIEW_ID_KEYWORDS.any { keyword ->
                node.viewId?.contains(keyword, ignoreCase = true) == true
            }
        } != null
        if (!onFeedTab) return RuleResult.NoAction

        if (eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
            accumulator.onScrollEvent()
        }

        val limitMs = settings.scrollLimitMinutes * 60_000L
        return if (accumulator.accumulatedMillis() >= limitMs) {
            RuleResult.Block(BlockReason.SCROLL_LIMIT)
        } else {
            RuleResult.NoAction
        }
    }

    override fun onSessionEnded() {
        accumulator.reset()
    }

    companion object {
        // Melhor esforço — confirmar contra a versão real do Instagram instalada.
        val FEED_TAB_VIEW_ID_KEYWORDS = listOf("feed_tab", "home_tab")
    }
}
