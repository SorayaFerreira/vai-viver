package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Test

class TabDiagnosticsTest {
    @Test
    fun `lists only selected nodes, in tree order, with their identifiers`() {
        val root = ScreenNode(
            viewId = "root", contentDescription = null, className = "FrameLayout",
            children = listOf(
                ScreenNode("com.instagram.android:id/feed_tab", "Página inicial", "FrameLayout", isSelected = true),
                ScreenNode("com.instagram.android:id/clips_tab", "Reels", "FrameLayout"),
                ScreenNode(null, null, "ImageView", isSelected = true)
            )
        )

        assertEquals(
            listOf(
                "viewId=com.instagram.android:id/feed_tab desc=Página inicial class=FrameLayout",
                "viewId=null desc=null class=ImageView"
            ),
            describeSelectedNodes(root)
        )
    }
}
