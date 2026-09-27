import 'package:vaiviver/domain/models/app_settings.dart';
import 'package:vaiviver/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppSettings? initial]) : _settings = initial ?? AppSettings.defaults;

  AppSettings _settings;
  int saveCallCount = 0;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    saveCallCount++;
  }
}
