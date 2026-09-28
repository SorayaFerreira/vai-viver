package com.sorayaferreira.vaiviver.detection

private const val MAX_ANCESTORS = 3
private const val MAX_DESC_CHARS = 40

/**
 * Debug aid for calibrating tab detection: every selected node on screen with
 * its nearest ancestors. Instagram marks the tab's child icon as selected
 * while the button that identifies the tab is an ancestor, so both are needed.
 * Identifiers only, descriptions truncated — never the text of posts.
 */
fun describeSelectedNodes(root: ScreenNode): List<String> {
    val out = mutableListOf<String>()
    val ancestors = ArrayDeque<ScreenNode>() // nearest first

    fun label(node: ScreenNode) =
        "viewId=${node.viewId} desc=${node.contentDescription?.take(MAX_DESC_CHARS)}"

    fun visit(node: ScreenNode) {
        if (node.isSelected) {
            val chain = ancestors.take(MAX_ANCESTORS).joinToString("") { " <- [${label(it)}]" }
            out += "${label(node)} class=${node.className}$chain"
        }
        ancestors.addFirst(node)
        node.children.forEach(::visit)
        ancestors.removeFirst()
    }
    visit(root)
    return out
}
