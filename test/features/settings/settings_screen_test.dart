import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/settings/settings_screen.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';

import '../../fakes/fake_settings_repository.dart';
import '../../helpers/phone_viewport.dart';
import '../../helpers/themed_app.dart';

void main() {
  testWidgets('toggling reels-block switch saves through the repository', (
    tester,
  ) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reels-block-switch')));
    await tester.pumpAndSettle();

    expect(fakeRepo.saveCallCount, 1);
  });

  testWidgets('changing the minutes stepper saves the new value', (
    tester,
  ) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scroll-limit-increment')));
    await tester.pumpAndSettle();

    expect((await fakeRepo.getSettings()).scrollLimitMinutes, 3);
  });

  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(
                FakeSettingsRepository(),
              ),
            ],
            child: themedApp(home: const SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });
}
