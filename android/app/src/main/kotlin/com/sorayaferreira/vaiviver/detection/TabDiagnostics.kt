package com.sorayaferreira.vaiviver.detection

/**
 * Debug aid for calibrating tab detection: the identifiers of every selected
 * node on screen (the active bottom-nav tab is one of them). Identifiers only —
 * never the text of posts.
 */
fun describeSelectedNodes(root: ScreenNode): List<String> {
    val out = mutableListOf<String>()
    fun visit(node: ScreenNode) {
        if (node.isSelected) {
            out += "viewId=${node.viewId} desc=${node.contentDescription} class=${node.className}"
        }
        node.children.forEach(::visit)
    }
    visit(root)
    return out
}
