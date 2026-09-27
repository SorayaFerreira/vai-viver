package com.sorayaferreira.vaiviver

import com.sorayaferreira.vaiviver.data.AndroidPermissionsChecker
import com.sorayaferreira.vaiviver.data.NativeBridge
import com.sorayaferreira.vaiviver.data.SettingsStore
import com.sorayaferreira.vaiviver.data.SharedPreferencesKeyValueStore
import com.sorayaferreira.vaiviver.data.StatsStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val keyValueStore = SharedPreferencesKeyValueStore(applicationContext)
        val bridge = NativeBridge(
            settingsStore = SettingsStore(keyValueStore),
            statsStore = StatsStore(keyValueStore),
            permissionsChecker = AndroidPermissionsChecker(applicationContext, keyValueStore)
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler(bridge)
    }

    companion object {
        private const val CHANNEL_NAME = "com.sorayaferreira.vaiviver/native"
    }
}
