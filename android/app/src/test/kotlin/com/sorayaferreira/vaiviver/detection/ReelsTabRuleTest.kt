package com.sorayaferreira.vaiviver.detection

import com.sorayaferreira.vaiviver.data.AppSettings
import com.sorayaferreira.vaiviver.data.InMemoryKeyValueStore
import com.sorayaferreira.vaiviver.data.SettingsStore
import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.assertEquals
import org.junit.Test

class ReelsTabRuleTest {
    private fun settingsStore(reelsEnabled: Boolean = true) =
        SettingsStore(InMemoryKeyValueStore()).apply {
            setSettings(AppSettings.DEFAULT.copy(reelsBlockEnabled = reelsEnabled))
        }

    @Test
    fun `blocks when a reels tab marker is present in the tree`() {
        val root = ScreenNode(
            viewId = "root",
            contentDescription = null,
            className = "FrameLayout",
            children = listOf(
                ScreenNode(viewId = "bottom_nav_reels", contentDescription = "Reels", className = "ImageView")
            )
        )
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.Block(BlockReason.REELS_TAB), result)
    }

    @Test
    fun `does nothing when reels blocking is disabled`() {
        val root = ScreenNode("root", "Reels", "ImageView")
        val rule = ReelsTabRule(settingsStore(reelsEnabled = false))

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.NoAction, result)
    }

    @Test
    fun `does nothing when no reels tab marker is present`() {
        val root = ScreenNode("root", null, "FrameLayout")
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.NoAction, result)
    }
}
