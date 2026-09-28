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

    // Shape seen on the device (log of 2026-09-28): the selected node is the
    // generic child icon; the button that identifies the tab is its parent.
    private fun tab(viewId: String, desc: String?, iconSelected: Boolean) = ScreenNode(
        viewId, desc, "FrameLayout",
        children = listOf(
            ScreenNode("com.instagram.android:id/tab_icon", null, "ImageView", isSelected = iconSelected)
        )
    )

    @Test
    fun `home button whose child icon is selected is the home tab`() {
        val screen = ScreenNode(
            "root", null, "FrameLayout",
            children = listOf(
                tab("com.instagram.android:id/feed_tab", null, iconSelected = true),
                tab("com.instagram.android:id/clips_tab", null, iconSelected = false)
            )
        )

        assertTrue(HomeTabDetector.isHomeTabSelected(screen))
    }

    @Test
    fun `a selected icon under another tab does not count as the home tab`() {
        val screen = ScreenNode(
            "root", null, "FrameLayout",
            children = listOf(
                tab("com.instagram.android:id/feed_tab", "Página inicial", iconSelected = false),
                tab("com.instagram.android:id/profile_tab", "Perfil", iconSelected = true)
            )
        )

        assertFalse(HomeTabDetector.isHomeTabSelected(screen))
    }
}
