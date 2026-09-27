import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/features/onboarding/onboarding_flow_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_stats_repository.dart';

void main() {
  testWidgets('walks through every step to the Home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(FakePermissionsRepository()),
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: const MaterialApp(home: OnboardingFlowScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vinda ao VaiViver'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('VaiViver'), findsOneWidget); // HomeScreen's AppBar title
  });
}
