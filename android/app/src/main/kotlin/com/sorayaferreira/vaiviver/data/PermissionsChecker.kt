package com.sorayaferreira.vaiviver.data

interface PermissionsChecker {
    fun isAccessibilityServiceEnabled(): Boolean
    fun isIgnoringBatteryOptimizations(): Boolean
    fun isAutostartAcknowledged(): Boolean
    fun setAutostartAcknowledged(value: Boolean)
    fun isOnboardingComplete(): Boolean
    fun setOnboardingComplete(value: Boolean)
    fun openAccessibilitySettings()
    fun openBatteryOptimizationSettings()
}
