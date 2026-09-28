package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore

class FeedScrollLimitRule(
    private val settingsStore: SettingsStore,
    private val accumulator: ScrollActivityAccumulator = ScrollActivityAccumulator()
) : DetectionRule {

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        val settings = settingsStore.getSettings()
        if (!settings.scrollLimitEnabled) {
            // Drop any partial progress so it can't carry over once re-enabled.
            accumulator.reset()
            return RuleResult.NoAction
        }

        // The bottom nav renders every tab's button on every screen; only the active
        // tab's button is selected. The marker must be on the selected node itself.
        val onFeedTab = root.findFirst { node ->
            node.isSelected && FEED_TAB_VIEW_ID_KEYWORDS.any { keyword ->
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
