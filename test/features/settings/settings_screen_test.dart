import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/settings/settings_screen.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';

import '../../fakes/fake_settings_repository.dart';

void main() {
  testWidgets('toggling reels-block switch saves through the repository', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: SettingsScreen(),
          routes: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reels-block-switch')));
    await tester.pumpAndSettle();

    expect(fakeRepo.saveCallCount, 1);
  });

  testWidgets('changing the minutes stepper saves the new value', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scroll-limit-increment')));
    await tester.pumpAndSettle();

    expect((await fakeRepo.getSettings()).scrollLimitMinutes, 3);
  });
}
