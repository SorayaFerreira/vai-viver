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
    private var countedThisSession = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        settingsStore = SettingsStore(keyValueStore)
        statsStore = StatsStore(keyValueStore)
        rules = listOf(
            ReelsTabRule(settingsStore),
            FeedScrollLimitRule(settingsStore)
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventPackage = event.packageName?.toString()

        if (eventPackage != INSTAGRAM_PACKAGE) {
            // Only a window-state change from another app means the user actually left
            // Instagram. Notifications, the keyboard, the volume panel etc. emit other
            // event types from other packages and must not reset the session.
            if (eventPackage != null &&
                event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            ) {
                endSession()
            }
            return
        }

        val rootNode = rootInActiveWindow ?: return // transient null: skip, don't crash
        // RF11: the event said Instagram, but the active window we actually read may belong
        // to another app (notification shade, split-screen, a race during app switch).
        // Never inspect another app's content.
        if (rootNode.packageName?.toString() != INSTAGRAM_PACKAGE) {
            rootNode.recycle()
            return
        }
        val screenNode = try {
            rootNode.toScreenNode()
        } finally {
            rootNode.recycle()
        }

        when (val result = evaluateRules(rules, screenNode, event.eventType)) {
            is RuleResult.Block -> {
                // Going Home on every matching event keeps enforcement robust against a
                // missed event; stats are counted only once per logical block (session).
                performGlobalAction(GLOBAL_ACTION_HOME)
                if (!countedThisSession) {
                    countedThisSession = true
                    when (result.reason) {
                        BlockReason.REELS_TAB -> statsStore.incrementReelsBlocked()
                        BlockReason.SCROLL_LIMIT -> statsStore.addScrollSecondsSaved(
                            settingsStore.getSettings().scrollLimitMinutes * 60
                        )
                    }
                }
            }
            RuleResult.NoAction -> Unit
        }
    }

    private fun endSession() {
        rules.forEach { it.onSessionEnded() }
        countedThisSession = false
    }

    override fun onInterrupt() = Unit

    companion object {
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
    }
}
