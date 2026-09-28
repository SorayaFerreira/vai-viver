package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityNodeInfo

@Suppress("DEPRECATION") // recycle() is a no-op on API 33+, kept for older devices
fun AccessibilityNodeInfo.toScreenNode(): ScreenNode {
    val children = mutableListOf<ScreenNode>()
    for (i in 0 until childCount) {
        val child = getChild(i) ?: continue
        children.add(child.toScreenNode())
        child.recycle()
    }
    return ScreenNode(
        viewId = viewIdResourceName,
        contentDescription = contentDescription?.toString(),
        className = className?.toString(),
        isSelected = isSelected,
        children = children
    )
}
