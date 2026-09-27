package com.sorayaferreira.vaiviver.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class InMemoryKeyValueStoreTest {
    @Test
    fun `returns defaults when nothing was stored`() {
        val store = InMemoryKeyValueStore()
        assertNull(store.getString("missing"))
        assertEquals(42, store.getInt("missing", 42))
        assertEquals(true, store.getBoolean("missing", true))
    }

    @Test
    fun `round-trips stored values`() {
        val store = InMemoryKeyValueStore()
        store.putString("s", "hello")
        store.putInt("i", 7)
        store.putBoolean("b", true)

        assertEquals("hello", store.getString("s"))
        assertEquals(7, store.getInt("i", 0))
        assertEquals(true, store.getBoolean("b", false))
    }
}
