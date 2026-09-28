package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HomeTabDetectorTest {
    private fun bottomNav(home: ScreenNode, reelsSelected: Boolean = false) = ScreenNode(
        viewId = "root", contentDescription = null, className = "FrameLayout",
        children = listOf(
            home,
            ScreenNode("clips_tab", "Reels", "FrameLayout", isSelected = reelsSelected)
        )
    )

    @Test
    fun `selected button with a known view id is the home tab`() {
        assertTrue(
            HomeTabDetector.isHomeTabSelected(
                bottomNav(ScreenNode("com.instagram.android:id/feed_tab", null, "FrameLayout", isSelected = true))
            )
        )
    }

    @Test
    fun `selected button with a known accessible name is the home tab, whatever its id`() {
        assertTrue(
            HomeTabDetector.isHomeTabSelected(
                bottomNav(ScreenNode("tab_0", "Página inicial", "FrameLayout", isSelected = true))
            )
        )
    }

    @Test
    fun `home button present but not selected is not the home tab`() {
        assertFalse(
            HomeTabDetector.isHomeTabSelected(
                bottomNav(ScreenNode("feed_tab", "Página inicial", "FrameLayout"), reelsSelected = true)
            )
        )
    }
}
