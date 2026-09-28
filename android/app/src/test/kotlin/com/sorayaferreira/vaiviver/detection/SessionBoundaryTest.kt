package com.sorayaferreira.vaiviver.detection

import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionBoundaryTest {
    @Test
    fun `another app taking the active window ends the session`() {
        assertTrue(isLeavingInstagram("com.miui.home", TYPE_WINDOW_STATE_CHANGED, "com.miui.home"))
    }

    @Test
    fun `a dialog from another package over Instagram does not (keyboard, volume, notification)`() {
        assertFalse(isLeavingInstagram("com.android.systemui", TYPE_WINDOW_STATE_CHANGED, INSTAGRAM_PACKAGE))
    }

    @Test
    fun `non window-state events from other packages are ignored`() {
        assertFalse(isLeavingInstagram("com.whatsapp", TYPE_WINDOW_CONTENT_CHANGED, "com.whatsapp"))
    }

    @Test
    fun `events without a package are ignored`() {
        assertFalse(isLeavingInstagram(null, TYPE_WINDOW_STATE_CHANGED, null))
    }
}
