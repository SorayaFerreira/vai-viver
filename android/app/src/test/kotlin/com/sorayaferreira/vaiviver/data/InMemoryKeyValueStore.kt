package com.sorayaferreira.vaiviver.data

class InMemoryKeyValueStore : KeyValueStore {
    private val strings = mutableMapOf<String, String>()
    private val ints = mutableMapOf<String, Int>()
    private val booleans = mutableMapOf<String, Boolean>()

    override fun getString(key: String): String? = strings[key]
    override fun putString(key: String, value: String) { strings[key] = value }
    override fun getInt(key: String, default: Int): Int = ints[key] ?: default
    override fun putInt(key: String, value: Int) { ints[key] = value }
    override fun getBoolean(key: String, default: Boolean): Boolean = booleans[key] ?: default
    override fun putBoolean(key: String, value: Boolean) { booleans[key] = value }
}
