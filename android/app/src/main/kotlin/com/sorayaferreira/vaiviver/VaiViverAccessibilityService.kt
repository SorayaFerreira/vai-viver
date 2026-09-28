package com.sorayaferreira.vaiviver

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.SharedPreferencesKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import com.sorayaferreira.vaiviver.detection.BlockReason
import com.sorayaferreira.vaiviver.detection.DetectionRule
import com.sorayaferreira.vaiviver.detection.FeedTimeLimitRule
import com.sorayaferreira.vaiviver.detection.FeedTimeTracker
import com.sorayaferreira.vaiviver.detection.INSTAGRAM_PACKAGE
import com.sorayaferreira.vaiviver.detection.ReelsTabRule
import com.sorayaferreira.vaiviver.detection.RuleResult
import com.sorayaferreira.vaiviver.detection.ScreenNode
import com.sorayaferreira.vaiviver.detection.describeSelectedNodes
import com.sorayaferreira.vaiviver.detection.evaluateRules
import com.sorayaferreira.vaiviver.detection.isLeavingInstagram
import com.sorayaferreira.vaiviver.detection.toScreenNode

class VaiViverAccessibilityService : AccessibilityService() {

    private lateinit var settingsStore: SettingsStore
    private lateinit var statsStore: StatsStore
    private lateinit var feedRule: FeedTimeLimitRule
    private lateinit var rules: List<DetectionRule>
    private var countedThisSession = false
    private var lastTabLog: List<String>? = null

    private val handler = Handler(Looper.getMainLooper())

    // Re-reads the screen when the feed limit (or the grace window) runs out,
    // for when the user sits on the feed and no events arrive.
    private val deadlineCheck = Runnable { checkInstagramWindow(eventType = 0) }

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = endSession()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        settingsStore = SettingsStore(keyValueStore)
        statsStore = StatsStore(keyValueStore)
        feedRule = FeedTimeLimitRule(settingsStore, FeedTimeTracker(statsStore))
        rules = listOf(ReelsTabRule(settingsStore), feedRule)

        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOffReceiver, filter)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventPackage = event.packageName?.toString()
        if (eventPackage == INSTAGRAM_PACKAGE) {
            checkInstagramWindow(event.eventType)
        } else if (isLeavingInstagram(eventPackage, event.eventType, activeWindowPackage())) {
            endSession()
        }
    }

    /** Reads the active window only if it is Instagram's (RF11) and applies the rules. */
    private fun checkInstagramWindow(eventType: Int) {
        val rootNode = rootInActiveWindow ?: return // transient null: skip, don't crash
        if (rootNode.packageName?.toString() != INSTAGRAM_PACKAGE) {
            rootNode.recycle()
            return
        }
        val screenNode = try {
            rootNode.toScreenNode()
        } finally {
            rootNode.recycle()
        }
        logSelectedTabs(screenNode)

        when (val result = evaluateRules(rules, screenNode, eventType)) {
            is RuleResult.Block -> {
                // Going Home on every matching event keeps enforcement robust against a
                // missed event; stats are counted only once per logical block (session).
                performGlobalAction(GLOBAL_ACTION_HOME)
                if (!countedThisSession) {
                    countedThisSession = true
                    when (result.reason) {
                        BlockReason.REELS_TAB -> statsStore.incrementReelsBlocked()
                        BlockReason.FEED_TIME_LIMIT -> statsStore.incrementFeedBlocked()
                    }
                }
            }
            RuleResult.NoAction -> Unit
        }
        scheduleDeadlineCheck()
    }

    private fun scheduleDeadlineCheck() {
        handler.removeCallbacks(deadlineCheck)
        feedRule.millisUntilNextCheck()?.let { delay ->
            handler.postDelayed(deadlineCheck, delay.coerceAtLeast(MIN_CHECK_DELAY_MS))
        }
    }

    @Suppress("DEPRECATION") // recycle() is a no-op on API 33+, kept for older devices
    private fun activeWindowPackage(): String? {
        val root = rootInActiveWindow ?: return null
        return try {
            root.packageName?.toString()
        } finally {
            root.recycle()
        }
    }

    private fun endSession() {
        handler.removeCallbacks(deadlineCheck)
        rules.forEach { it.onSessionEnded() }
        countedThisSession = false
    }

    /** Debug builds only: logs the selected nodes whenever they change. */
    private fun logSelectedTabs(screen: ScreenNode) {
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        val summary = describeSelectedNodes(screen)
        if (summary != lastTabLog) {
            lastTabLog = summary
            Log.d(TAG, "selected: $summary")
        }
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        runCatching { unregisterReceiver(screenOffReceiver) }
        super.onDestroy()
    }

    companion object {
        private const val TAG = "VaiViver/tabs"
        private const val MIN_CHECK_DELAY_MS = 500L
    }
}
