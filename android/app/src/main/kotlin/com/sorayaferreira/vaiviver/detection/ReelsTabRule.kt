package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.SettingsStore

class ReelsTabRule(private val settingsStore: SettingsStore) : DetectionRule {

    override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
        if (!settingsStore.getSettings().reelsBlockEnabled) return RuleResult.NoAction

        val onReelsTab = root.findFirst { node ->
            REELS_TAB_VIEW_ID_KEYWORDS.any { keyword ->
                node.viewId?.contains(keyword, ignoreCase = true) == true
            } ||
                REELS_TAB_CONTENT_DESCRIPTIONS.any { desc ->
                    node.contentDescription?.equals(desc, ignoreCase = true) == true
                }
        } != null

        return if (onReelsTab) RuleResult.Block(BlockReason.REELS_TAB) else RuleResult.NoAction
    }

    companion object {
        // Melhor esforço — confirmar contra a versão real do Instagram instalada
        // (ver docs/manual-test-checklist.md).
        val REELS_TAB_VIEW_ID_KEYWORDS = listOf("clips_tab", "reels_tab")
        val REELS_TAB_CONTENT_DESCRIPTIONS = listOf("Reels")
    }
}
