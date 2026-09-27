package com.sorayaferreira.vaiviver.data

class SettingsStore(private val store: KeyValueStore) {
    fun getSettings(): AppSettings = AppSettings(
        reelsBlockEnabled = store.getBoolean(KEY_REELS_BLOCK_ENABLED, AppSettings.DEFAULT.reelsBlockEnabled),
        scrollLimitEnabled = store.getBoolean(KEY_SCROLL_LIMIT_ENABLED, AppSettings.DEFAULT.scrollLimitEnabled),
        scrollLimitMinutes = store.getInt(KEY_SCROLL_LIMIT_MINUTES, AppSettings.DEFAULT.scrollLimitMinutes)
    )

    fun setSettings(settings: AppSettings) {
        store.putBoolean(KEY_REELS_BLOCK_ENABLED, settings.reelsBlockEnabled)
        store.putBoolean(KEY_SCROLL_LIMIT_ENABLED, settings.scrollLimitEnabled)
        store.putInt(KEY_SCROLL_LIMIT_MINUTES, settings.scrollLimitMinutes)
    }

    companion object {
        private const val KEY_REELS_BLOCK_ENABLED = "reels_block_enabled"
        private const val KEY_SCROLL_LIMIT_ENABLED = "scroll_limit_enabled"
        private const val KEY_SCROLL_LIMIT_MINUTES = "scroll_limit_minutes"
    }
}
