package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent

const val INSTAGRAM_PACKAGE = "com.instagram.android"

/**
 * Whether an event from another package means the user really left Instagram.
 * The keyboard, the volume panel and notifications are dialogs owned by other
 * packages and also emit TYPE_WINDOW_STATE_CHANGED, so the event alone isn't
 * enough: the active window must no longer be Instagram's. Only package names
 * are compared — no other app's content is read.
 *
 * [activeWindowPackage] is called only when the event itself can't settle it:
 * reading the active window is a call into the foreground app, and content
 * changes from every app reach the service several times a second.
 */
fun isLeavingInstagram(eventPackage: String?, eventType: Int, activeWindowPackage: () -> String?): Boolean =
    eventPackage != null &&
        eventPackage != INSTAGRAM_PACKAGE &&
        eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
        activeWindowPackage() != INSTAGRAM_PACKAGE
