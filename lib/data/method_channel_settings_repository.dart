import '../core/native_bridge.dart';
import '../domain/models/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class MethodChannelSettingsRepository implements SettingsRepository {
  MethodChannelSettingsRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<AppSettings> getSettings() async {
    final map = await _bridge.channel.invokeMapMethod<String, Object?>(
      'getSettings',
    );
    return AppSettings(
      reelsBlockEnabled: map!['reelsBlockEnabled'] as bool,
      scrollLimitEnabled: map['scrollLimitEnabled'] as bool,
      scrollLimitMinutes: map['scrollLimitMinutes'] as int,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _bridge.channel.invokeMethod('setSettings', {
      'reelsBlockEnabled': settings.reelsBlockEnabled,
      'scrollLimitEnabled': settings.scrollLimitEnabled,
      'scrollLimitMinutes': settings.scrollLimitMinutes,
    });
  }
}
