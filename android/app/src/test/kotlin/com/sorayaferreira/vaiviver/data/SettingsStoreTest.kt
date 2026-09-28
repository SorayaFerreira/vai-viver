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
            feedLimitEnabled = true,
            feedLimitMinutes = 25
        )

        store.setSettings(settings)

        assertEquals(settings, store.getSettings())
    }

    @Test
    fun `default daily feed limit is 20 minutes`() {
        assertEquals(20, SettingsStore(InMemoryKeyValueStore()).getSettings().feedLimitMinutes)
    }
}
