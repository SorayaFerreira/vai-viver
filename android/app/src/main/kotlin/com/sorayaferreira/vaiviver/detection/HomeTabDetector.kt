package com.sorayaferreira.vaiviver.detection

/**
 * Tells whether Instagram's Home (Início) tab is the selected one. The bottom
 * nav renders every tab's button on every screen; only the active one is
 * selected. The button is recognised by view id or accessible name (so one
 * wrong guess doesn't blind it), and the selection marker may be on the button
 * itself or on a descendant: on the device Instagram marks the child icon
 * ("tab_icon", no description), not the button.
 */
object HomeTabDetector {
    // Calibrated against the installed Instagram in Task 9 (logs from Task 1).
    val VIEW_ID_KEYWORDS = listOf("feed_tab", "home_tab")
    val CONTENT_DESCRIPTIONS = listOf("Página inicial", "Início", "Home")

    fun isHomeTabSelected(root: ScreenNode): Boolean = root.findFirst { node ->
        isHomeButton(node) && node.findFirst { it.isSelected } != null
    } != null

    private fun isHomeButton(node: ScreenNode): Boolean =
        VIEW_ID_KEYWORDS.any { node.viewId?.contains(it, ignoreCase = true) == true } ||
            CONTENT_DESCRIPTIONS.any { node.contentDescription?.equals(it, ignoreCase = true) == true }
}
