package com.sorayaferreira.vaiviver.data

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridge(
    private val settingsStore: SettingsStore,
    private val statsStore: StatsStore,
    private val permissionsChecker: PermissionsChecker
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSettings" -> {
                val s = settingsStore.getSettings()
                result.success(
                    mapOf(
                        "reelsBlockEnabled" to s.reelsBlockEnabled,
                        "scrollLimitEnabled" to s.scrollLimitEnabled,
                        "scrollLimitMinutes" to s.scrollLimitMinutes
                    )
                )
            }
            "setSettings" -> {
                val args = call.arguments as Map<*, *>
                settingsStore.setSettings(
                    AppSettings(
                        reelsBlockEnabled = args["reelsBlockEnabled"] as Boolean,
                        scrollLimitEnabled = args["scrollLimitEnabled"] as Boolean,
                        scrollLimitMinutes = (args["scrollLimitMinutes"] as Number).toInt()
                    )
                )
                result.success(null)
            }
            "getTodayStats" -> {
                val stats = statsStore.getToday()
                result.success(
                    mapOf(
                        "reelsBlockedCount" to stats.reelsBlockedCount,
                        "scrollSecondsSaved" to stats.scrollSecondsSaved
                    )
                )
            }
            "getPermissionStatus" -> {
                result.success(
                    mapOf(
                        "accessibilityEnabled" to permissionsChecker.isAccessibilityServiceEnabled(),
                        "batteryOptimizationIgnored" to permissionsChecker.isIgnoringBatteryOptimizations(),
                        "autostartAcknowledged" to permissionsChecker.isAutostartAcknowledged()
                    )
                )
            }
            "setAutostartAcknowledged" -> {
                val args = call.arguments as Map<*, *>
                permissionsChecker.setAutostartAcknowledged(args["value"] as Boolean)
                result.success(null)
            }
            "openAccessibilitySettings" -> {
                permissionsChecker.openAccessibilitySettings()
                result.success(null)
            }
            "openBatteryOptimizationSettings" -> {
                permissionsChecker.openBatteryOptimizationSettings()
                result.success(null)
            }
            "getOnboardingComplete" -> result.success(permissionsChecker.isOnboardingComplete())
            "setOnboardingComplete" -> {
                val args = call.arguments as Map<*, *>
                permissionsChecker.setOnboardingComplete(args["value"] as Boolean)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
