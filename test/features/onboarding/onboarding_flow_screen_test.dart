import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/home/home_screen.dart';
import 'package:vaiviver/features/onboarding/onboarding_flow_screen.dart';
import 'package:vaiviver/features/permissions/battery_optimization_status_tile.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_stats_repository.dart';
import '../../helpers/phone_viewport.dart';
import '../../helpers/themed_app.dart';

void main() {
  testWidgets('walks through every step to the Home screen', (tester) async {
    final fakePermissionsRepo = FakePermissionsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsRepositoryProvider.overrideWithValue(fakePermissionsRepo),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        ],
        child: themedApp(home: const OnboardingFlowScreen()),
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
    expect(fakePermissionsRepo.setOnboardingCompleteCallCount, 1);
  });

  testWidgets(
    'accessibility step blocks advancing until the permission is granted, re-checked on resume',
    (tester) async {
      final fakePermissionsRepo = FakePermissionsRepository(
        status: const PermissionStatus(
          accessibilityEnabled: false,
          batteryOptimizationIgnored: true,
          autostartAcknowledged: true,
        ),
      );
      await tester.pumpWidget(_wrap(fakePermissionsRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Próximo')); // Welcome -> Accessibility
      await tester.pumpAndSettle();

      ElevatedButton nextButton() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Próximo'),
      );
      expect(nextButton().onPressed, isNull);

      // User grants Accessibility in system Settings, then returns to the app.
      fakePermissionsRepo.status = const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: true,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(nextButton().onPressed, isNotNull);
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.byType(BatteryOptimizationStatusTile), findsOneWidget);
    },
  );

  testWidgets(
    'a failure to save onboarding completion shows a SnackBar and stays on onboarding',
    (tester) async {
      final fakePermissionsRepo = FakePermissionsRepository()
        ..setOnboardingCompleteError = PlatformException(
          code: 'unavailable',
          message: 'canal fora',
        );
      await tester.pumpWidget(_wrap(fakePermissionsRepo));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      expect(fakePermissionsRepo.setOnboardingCompleteCallCount, 1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Erro ao concluir'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Concluir'), findsOneWidget);
    },
  );

  // Regression for the reported bug: permission explanations ran off the
  // screen (under the status bar, and past the bottom with large fonts).
  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('every step on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          _wrap(
            FakePermissionsRepository(
              status: const PermissionStatus(
                accessibilityEnabled: false,
                batteryOptimizationIgnored: false,
                autostartAcknowledged: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pages = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        for (var page = 0; page < 5; page++) {
          pages.jumpToPage(page);
          await tester.pumpAndSettle();
          await expectContentFitsScreen(tester, viewport);
        }
      });
    }
  });
}

Widget _wrap(FakePermissionsRepository permissionsRepo) {
  return ProviderScope(
    overrides: [
      permissionsRepositoryProvider.overrideWithValue(permissionsRepo),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
    ],
    child: themedApp(home: const OnboardingFlowScreen()),
  );
}
