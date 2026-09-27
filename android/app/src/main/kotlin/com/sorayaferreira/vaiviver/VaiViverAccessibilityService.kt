package com.sorayaferreira.vaiviver

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.SharedPreferencesKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import com.sorayaferreira.vaiviver.detection.BlockReason
import com.sorayaferreira.vaiviver.detection.DetectionRule
import com.sorayaferreira.vaiviver.detection.FeedScrollLimitRule
import com.sorayaferreira.vaiviver.detection.ReelsTabRule
import com.sorayaferreira.vaiviver.detection.RuleResult
import com.sorayaferreira.vaiviver.detection.evaluateRules
import com.sorayaferreira.vaiviver.detection.toScreenNode

class VaiViverAccessibilityService : AccessibilityService() {

    private lateinit var settingsStore: SettingsStore
    private lateinit var statsStore: StatsStore
    private lateinit var rules: List<DetectionRule>

    override fun onServiceConnected() {
        super.onServiceConnected()
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        settingsStore = SettingsStore(keyValueStore)
        statsStore = StatsStore(keyValueStore)
        rules = listOf(
            ReelsTabRule(settingsStore),
            FeedScrollLimitRule(settingsStore, statsStore)
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventPackage = event.packageName?.toString()

        if (eventPackage != INSTAGRAM_PACKAGE) {
            // Any other app coming to the foreground ends the Instagram session.
            if (eventPackage != null) {
                rules.forEach { it.onSessionEnded() }
            }
            return
        }

        val rootNode = rootInActiveWindow ?: return // transient null: skip, don't crash
        val screenNode = try {
            rootNode.toScreenNode()
        } finally {
            rootNode.recycle()
        }

        when (val result = evaluateRules(rules, screenNode, event.eventType)) {
            is RuleResult.Block -> {
                performGlobalAction(GLOBAL_ACTION_HOME)
                when (result.reason) {
                    BlockReason.REELS_TAB -> statsStore.incrementReelsBlocked()
                    BlockReason.SCROLL_LIMIT -> statsStore.addScrollSecondsSaved(
                        settingsStore.getSettings().scrollLimitMinutes * 60
                    )
                }
            }
            RuleResult.NoAction -> Unit
        }
    }

    override fun onInterrupt() = Unit

    companion object {
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
    }
}
