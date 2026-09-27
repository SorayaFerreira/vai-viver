package com.sorayaferreira.vaiviver.data

data class AppSettings(
    val reelsBlockEnabled: Boolean,
    val scrollLimitEnabled: Boolean,
    val scrollLimitMinutes: Int
) {
    companion object {
        val DEFAULT = AppSettings(
            reelsBlockEnabled = true,
            scrollLimitEnabled = true,
            scrollLimitMinutes = 2
        )
    }
}
