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
                        "feedLimitEnabled" to s.feedLimitEnabled,
                        "feedLimitMinutes" to s.feedLimitMinutes
                    )
                )
            }
            "setSettings" -> {
                val args = call.arguments as Map<*, *>
                settingsStore.setSettings(
                    AppSettings(
                        reelsBlockEnabled = args["reelsBlockEnabled"] as Boolean,
                        feedLimitEnabled = args["feedLimitEnabled"] as Boolean,
                        feedLimitMinutes = (args["feedLimitMinutes"] as Number).toInt()
                    )
                )
                result.success(null)
            }
            "getTodayStats" -> {
                val stats = statsStore.getToday()
                result.success(
                    mapOf(
                        "reelsBlockedCount" to stats.reelsBlockedCount,
                        "feedSecondsToday" to stats.feedSecondsToday,
                        "feedBlockedCount" to stats.feedBlockedCount
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
