package com.sorayaferreira.vaiviver.data

class FakePermissionsChecker(
    var accessibilityEnabled: Boolean = false,
    var accessibilityRunning: Boolean = false,
    var batteryOptimizationIgnored: Boolean = false,
    private var autostartAcknowledged: Boolean = false,
    private var onboardingComplete: Boolean = false
) : PermissionsChecker {
    var openAccessibilitySettingsCallCount = 0
        private set
    var openBatteryOptimizationSettingsCallCount = 0
        private set

    override fun isAccessibilityServiceEnabled() = accessibilityEnabled
    override fun isAccessibilityServiceRunning() = accessibilityRunning
    override fun isIgnoringBatteryOptimizations() = batteryOptimizationIgnored
    override fun isAutostartAcknowledged() = autostartAcknowledged
    override fun setAutostartAcknowledged(value: Boolean) { autostartAcknowledged = value }
    override fun isOnboardingComplete() = onboardingComplete
    override fun setOnboardingComplete(value: Boolean) { onboardingComplete = value }
    override fun openAccessibilitySettings() { openAccessibilitySettingsCallCount++ }
    override fun openBatteryOptimizationSettings() { openBatteryOptimizationSettingsCallCount++ }
}
