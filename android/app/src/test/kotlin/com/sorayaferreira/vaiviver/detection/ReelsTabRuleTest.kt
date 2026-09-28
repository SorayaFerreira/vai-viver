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

    /** Instagram-like bottom nav: every tab button is always present, only one is selected. */
    private fun screenWithBottomNav(feedSelected: Boolean, reelsSelected: Boolean) = ScreenNode(
        viewId = "root",
        contentDescription = null,
        className = "FrameLayout",
        children = listOf(
            ScreenNode(viewId = "content", contentDescription = null, className = "FrameLayout"),
            ScreenNode(
                viewId = "tab_bar",
                contentDescription = null,
                className = "LinearLayout",
                children = listOf(
                    ScreenNode(
                        viewId = "feed_tab",
                        contentDescription = "Home",
                        className = "FrameLayout",
                        isSelected = feedSelected
                    ),
                    ScreenNode(
                        viewId = "search_tab",
                        contentDescription = "Search and explore",
                        className = "FrameLayout"
                    ),
                    ScreenNode(
                        viewId = "clips_tab",
                        contentDescription = "Reels",
                        className = "FrameLayout",
                        isSelected = reelsSelected
                    ),
                    ScreenNode(
                        viewId = "profile_tab",
                        contentDescription = "Profile",
                        className = "FrameLayout"
                    )
                )
            )
        )
    )

    @Test
    fun `blocks when a reels tab marker is present in the tree`() {
        val root = ScreenNode(
            viewId = "root",
            contentDescription = null,
            className = "FrameLayout",
            children = listOf(
                ScreenNode(
                    viewId = "bottom_nav_reels",
                    contentDescription = "Reels",
                    className = "ImageView",
                    isSelected = true
                )
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

    @Test
    fun `does nothing when the reels button is present but the feed tab is the selected one`() {
        val root = screenWithBottomNav(feedSelected = true, reelsSelected = false)
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.NoAction, result)
    }

    @Test
    fun `blocks when the full bottom nav is present and the reels tab is the selected one`() {
        val root = screenWithBottomNav(feedSelected = false, reelsSelected = true)
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.Block(BlockReason.REELS_TAB), result)
    }

    @Test
    fun `does not treat a selected non-reels node as the reels tab`() {
        // isSelected must be on the SAME node carrying the reels marker, not anywhere in the tree.
        val root = ScreenNode(
            viewId = "root",
            contentDescription = null,
            className = "FrameLayout",
            children = listOf(
                ScreenNode(viewId = "clips_tab", contentDescription = "Reels", className = "FrameLayout"),
                ScreenNode(viewId = "unrelated", contentDescription = null, className = "View", isSelected = true)
            )
        )
        val rule = ReelsTabRule(settingsStore())

        val result = rule.evaluate(root, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)

        assertEquals(RuleResult.NoAction, result)
    }
}
