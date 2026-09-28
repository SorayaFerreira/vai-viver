import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';

import '../../fakes/fake_settings_repository.dart';

void main() {
  test('setScrollLimitMinutes saves and updates state', () async {
    final fakeRepo = FakeSettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setScrollLimitMinutes(7);

    expect(
      container.read(settingsViewModelProvider).value!.scrollLimitMinutes,
      7,
    );
    expect(fakeRepo.saveCallCount, 1);
  });

  test('setReelsBlockEnabled saves and updates state', () async {
    final fakeRepo = FakeSettingsRepository();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setReelsBlockEnabled(false);

    expect(
      container.read(settingsViewModelProvider).value!.reelsBlockEnabled,
      false,
    );
  });

  test('a failed save surfaces as AsyncError instead of throwing', () async {
    final fakeRepo = FakeSettingsRepository()
      ..saveError = PlatformException(code: 'unavailable');
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsViewModelProvider.future);
    await container
        .read(settingsViewModelProvider.notifier)
        .setScrollLimitEnabled(false);

    final state = container.read(settingsViewModelProvider);
    expect(fakeRepo.saveCallCount, 1);
    expect(state.isLoading, false);
    expect(state.error, isA<PlatformException>());
  });
}
