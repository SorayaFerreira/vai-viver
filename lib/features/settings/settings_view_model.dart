import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_bridge.dart';
import '../../data/method_channel_settings_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MethodChannelSettingsRepository(NativeBridge());
});

class SettingsViewModel extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).getSettings();
  }

  Future<void> setReelsBlockEnabled(bool value) =>
      _update((s) => s.copyWith(reelsBlockEnabled: value));
  Future<void> setFeedLimitEnabled(bool value) =>
      _update((s) => s.copyWith(feedLimitEnabled: value));
  Future<void> setFeedLimitMinutes(int minutes) =>
      _update((s) => s.copyWith(feedLimitMinutes: minutes));

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    final current = state.value;
    if (current == null) return;
    final updated = transform(current);
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).saveSettings(updated);
      return updated;
    });
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, AppSettings>(
      SettingsViewModel.new,
    );
