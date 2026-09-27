package com.sorayaferreira.vaiviver.data

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test

private class RecordingResult : MethodChannel.Result {
    var success: Any? = null
    var errorCode: String? = null

    override fun success(result: Any?) { success = result }
    override fun error(code: String, message: String?, details: Any?) { errorCode = code }
    override fun notImplemented() { fail("unexpected notImplemented") }
}

class NativeBridgeTest {
    private fun bridge(
        settingsStore: SettingsStore = SettingsStore(InMemoryKeyValueStore()),
        statsStore: StatsStore = StatsStore(InMemoryKeyValueStore()),
        permissionsChecker: FakePermissionsChecker = FakePermissionsChecker()
    ) = NativeBridge(settingsStore, statsStore, permissionsChecker)

    @Test
    fun `getSettings returns the current settings as a map`() {
        val settingsStore = SettingsStore(InMemoryKeyValueStore()).apply {
            setSettings(AppSettings.DEFAULT.copy(scrollLimitMinutes = 5))
        }
        val result = RecordingResult()

        bridge(settingsStore = settingsStore).onMethodCall(MethodCall("getSettings", null), result)

        val map = result.success as Map<*, *>
        assertEquals(5, map["scrollLimitMinutes"])
        assertEquals(true, map["reelsBlockEnabled"])
    }

    @Test
    fun `setSettings persists the given values`() {
        val settingsStore = SettingsStore(InMemoryKeyValueStore())
        val result = RecordingResult()
        val args = mapOf(
            "reelsBlockEnabled" to false,
            "scrollLimitEnabled" to true,
            "scrollLimitMinutes" to 7
        )

        bridge(settingsStore = settingsStore).onMethodCall(MethodCall("setSettings", args), result)

        assertEquals(7, settingsStore.getSettings().scrollLimitMinutes)
        assertEquals(false, settingsStore.getSettings().reelsBlockEnabled)
    }

    @Test
    fun `getPermissionStatus reflects the permissions checker`() {
        val checker = FakePermissionsChecker(accessibilityEnabled = true, batteryOptimizationIgnored = false)
        val result = RecordingResult()

        bridge(permissionsChecker = checker).onMethodCall(MethodCall("getPermissionStatus", null), result)

        val map = result.success as Map<*, *>
        assertEquals(true, map["accessibilityEnabled"])
        assertEquals(false, map["batteryOptimizationIgnored"])
    }

    @Test
    fun `unknown method calls notImplemented`() {
        var notImplementedCalled = false
        val result = object : MethodChannel.Result {
            override fun success(result: Any?) = fail("unexpected success")
            override fun error(code: String, message: String?, details: Any?) = fail("unexpected error")
            override fun notImplemented() { notImplementedCalled = true }
        }

        bridge().onMethodCall(MethodCall("somethingElse", null), result)

        assertEquals(true, notImplementedCalled)
    }
}
