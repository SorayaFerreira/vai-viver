package com.sorayaferreira.vaiviver.detection

/**
 * Tells whether Instagram's Home (Início) tab is the selected one. The bottom
 * nav renders every tab's button on every screen; only the active one is
 * selected, and the marker must be on that node itself. Matches by view id or
 * by accessible name, like ReelsTabRule, so one wrong guess doesn't blind it.
 */
object HomeTabDetector {
    // Calibrated against the installed Instagram in Task 9 (logs from Task 1).
    val VIEW_ID_KEYWORDS = listOf("feed_tab", "home_tab")
    val CONTENT_DESCRIPTIONS = listOf("Página inicial", "Início", "Home")

    fun isHomeTabSelected(root: ScreenNode): Boolean = root.findFirst { node ->
        node.isSelected && (
            VIEW_ID_KEYWORDS.any { node.viewId?.contains(it, ignoreCase = true) == true } ||
                CONTENT_DESCRIPTIONS.any { node.contentDescription?.equals(it, ignoreCase = true) == true }
            )
    } != null
}
