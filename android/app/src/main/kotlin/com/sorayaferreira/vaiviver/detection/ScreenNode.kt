package com.sorayaferreira.vaiviver.detection

data class ScreenNode(
    val viewId: String?,
    val contentDescription: String?,
    val className: String?,
    val isSelected: Boolean = false,
    val children: List<ScreenNode> = emptyList()
) {
    fun findFirst(predicate: (ScreenNode) -> Boolean): ScreenNode? {
        if (predicate(this)) return this
        for (child in children) {
            child.findFirst(predicate)?.let { return it }
        }
        return null
    }
}
