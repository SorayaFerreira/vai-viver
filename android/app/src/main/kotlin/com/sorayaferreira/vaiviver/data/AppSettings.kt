package com.sorayaferreira.vaiviver.data

data class AppSettings(
    val reelsBlockEnabled: Boolean,
    val feedLimitEnabled: Boolean,
    val feedLimitMinutes: Int
) {
    companion object {
        val DEFAULT = AppSettings(
            reelsBlockEnabled = true,
            feedLimitEnabled = true,
            feedLimitMinutes = 20
        )
    }
}
