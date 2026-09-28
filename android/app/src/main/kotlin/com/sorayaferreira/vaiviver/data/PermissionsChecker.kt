package com.sorayaferreira.vaiviver.data

interface PermissionsChecker {
    fun isAccessibilityServiceEnabled(): Boolean

    /**
     * Whether Android actually has the service connected. Enabled-but-not-running
     * is what Settings shows as "malfunctioning" (e.g. after MIUI kills the app
     * when it is swiped away from recents).
     */
    fun isAccessibilityServiceRunning(): Boolean
    fun isIgnoringBatteryOptimizations(): Boolean
    fun isAutostartAcknowledged(): Boolean
    fun setAutostartAcknowledged(value: Boolean)
    fun isOnboardingComplete(): Boolean
    fun setOnboardingComplete(value: Boolean)
    fun openAccessibilitySettings()
    fun openBatteryOptimizationSettings()
}
