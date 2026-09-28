import 'package:vaiviver/domain/models/app_settings.dart';
import 'package:vaiviver/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppSettings? initial])
    : _settings = initial ?? AppSettings.defaults;

  AppSettings _settings;
  int saveCallCount = 0;

  /// When non-null, [saveSettings] throws this (after counting the call).
  Object? saveError;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    saveCallCount++;
    if (saveError != null) throw saveError!;
    _settings = settings;
  }
}
