package com.sorayaferreira.vaiviver.data

import org.junit.Assert.assertEquals
import org.junit.Test

class SettingsStoreTest {
    @Test
    fun `returns defaults when nothing was saved`() {
        val store = SettingsStore(InMemoryKeyValueStore())
        assertEquals(AppSettings.DEFAULT, store.getSettings())
    }

    @Test
    fun `round-trips saved settings`() {
        val store = SettingsStore(InMemoryKeyValueStore())
        val settings = AppSettings(
            reelsBlockEnabled = false,
            scrollLimitEnabled = true,
            scrollLimitMinutes = 5
        )

        store.setSettings(settings)

        assertEquals(settings, store.getSettings())
    }
}
