package com.sorayaferreira.vaiviver.data

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import com.sorayaferreira.vaiviver.VaiViverAccessibilityService

class AndroidPermissionsChecker(
    private val context: Context,
    private val keyValueStore: KeyValueStore
) : PermissionsChecker {

    override fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "${context.packageName}/${VaiViverAccessibilityService::class.java.name}"
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(":").any { it.equals(expected, ignoreCase = true) }
    }

    // The "enabled" list below only contains services Android has bound, so a
    // crashed/killed service waiting to be restarted is missing from it.
    override fun isAccessibilityServiceRunning(): Boolean {
        val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        return manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { info ->
                val service = info.resolveInfo.serviceInfo
                service.packageName == context.packageName &&
                    service.name == VaiViverAccessibilityService::class.java.name
            }
    }

    override fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    override fun isAutostartAcknowledged(): Boolean = keyValueStore.getBoolean(KEY_AUTOSTART_ACK, false)

    override fun setAutostartAcknowledged(value: Boolean) {
        keyValueStore.putBoolean(KEY_AUTOSTART_ACK, value)
    }

    override fun isOnboardingComplete(): Boolean = keyValueStore.getBoolean(KEY_ONBOARDING_COMPLETE, false)

    override fun setOnboardingComplete(value: Boolean) {
        keyValueStore.putBoolean(KEY_ONBOARDING_COMPLETE, value)
    }

    override fun openAccessibilitySettings() {
        context.startActivity(
            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    override fun openBatteryOptimizationSettings() {
        context.startActivity(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:${context.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    companion object {
        private const val KEY_AUTOSTART_ACK = "autostart_acknowledged"
        private const val KEY_ONBOARDING_COMPLETE = "onboarding_complete"
    }
}
