package com.sorayaferreira.vaiviver.data

class SettingsStore(private val store: KeyValueStore) {
    fun getSettings(): AppSettings = AppSettings(
        reelsBlockEnabled = store.getBoolean(KEY_REELS_BLOCK_ENABLED, AppSettings.DEFAULT.reelsBlockEnabled),
        feedLimitEnabled = store.getBoolean(KEY_FEED_LIMIT_ENABLED, AppSettings.DEFAULT.feedLimitEnabled),
        feedLimitMinutes = store.getInt(KEY_FEED_LIMIT_MINUTES, AppSettings.DEFAULT.feedLimitMinutes)
    )

    fun setSettings(settings: AppSettings) {
        store.putBoolean(KEY_REELS_BLOCK_ENABLED, settings.reelsBlockEnabled)
        store.putBoolean(KEY_FEED_LIMIT_ENABLED, settings.feedLimitEnabled)
        store.putInt(KEY_FEED_LIMIT_MINUTES, settings.feedLimitMinutes)
    }

    companion object {
        private const val KEY_REELS_BLOCK_ENABLED = "reels_block_enabled"
        private const val KEY_FEED_LIMIT_ENABLED = "feed_limit_enabled"
        private const val KEY_FEED_LIMIT_MINUTES = "feed_limit_minutes"
    }
}
