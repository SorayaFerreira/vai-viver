package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Test

class TabDiagnosticsTest {
    // Shape seen on the device: Instagram marks the tab's child icon as
    // selected, not the tab button that carries the identifiers.
    private fun tabBar(vararg tabs: ScreenNode) = ScreenNode(
        viewId = "root", contentDescription = null, className = "FrameLayout",
        children = listOf(ScreenNode("tab_bar", null, "LinearLayout", children = tabs.toList()))
    )

    private fun tab(viewId: String, desc: String, selected: Boolean) = ScreenNode(
        viewId, desc, "FrameLayout",
        children = listOf(ScreenNode("tab_icon", null, "ImageView", isSelected = selected))
    )

    @Test
    fun `lists each selected node with its nearest ancestors, in tree order`() {
        val root = tabBar(
            tab("feed_tab", "Página inicial", selected = true),
            tab("clips_tab", "Reels", selected = false)
        )

        assertEquals(
            listOf(
                "viewId=tab_icon desc=null class=ImageView" +
                    " <- [viewId=feed_tab desc=Página inicial]" +
                    " <- [viewId=tab_bar desc=null]" +
                    " <- [viewId=root desc=null]"
            ),
            describeSelectedNodes(root)
        )
    }

    @Test
    fun `stops at three ancestors and truncates long descriptions`() {
        val deep = ScreenNode(
            "a", null, "FrameLayout",
            children = listOf(
                ScreenNode(
                    "b", "x".repeat(60), "FrameLayout",
                    children = listOf(
                        ScreenNode(
                            "c", null, "FrameLayout",
                            children = listOf(
                                ScreenNode(
                                    "d", null, "FrameLayout",
                                    children = listOf(ScreenNode("e", null, "ImageView", isSelected = true))
                                )
                            )
                        )
                    )
                )
            )
        )

        assertEquals(
            listOf(
                "viewId=e desc=null class=ImageView" +
                    " <- [viewId=d desc=null]" +
                    " <- [viewId=c desc=null]" +
                    " <- [viewId=b desc=${"x".repeat(40)}]"
            ),
            describeSelectedNodes(deep)
        )
    }
}
