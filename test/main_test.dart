import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';
import 'package:vaiviver/main.dart';

import 'fakes/fake_permissions_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_stats_repository.dart';

void main() {
  testWidgets('shows onboarding when it has not been completed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(onboardingComplete: false),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const VaiViverApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vinda ao VaiViver'), findsOneWidget);
  });

  testWidgets('shows Home when onboarding was already completed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(onboardingComplete: true),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const VaiViverApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VaiViver'), findsOneWidget);
    expect(find.text('Bem-vinda ao VaiViver'), findsNothing);
  });
}
