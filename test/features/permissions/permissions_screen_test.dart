import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/permissions/permissions_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../helpers/phone_viewport.dart';
import '../../helpers/themed_app.dart';

void main() {
  testWidgets('shows granted/pending state for each permission', (
    tester,
  ) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: false,
        autostartAcknowledged: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Acessibilidade: ativada'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Otimização de bateria: pendente'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the autostart checkbox acknowledges it', (tester) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The cards are tall now; scroll the checkbox into view like a user would.
    final checkbox = find.byKey(const Key('autostart-ack-checkbox'));
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    expect(fakeRepo.status.autostartAcknowledged, true);
  });

  testWidgets('only a pending permission offers its fix button', (
    tester,
  ) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: false,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Granted battery: no fix button for it.
    expect(find.text('Pedir isenção'), findsNothing);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    expect(fakeRepo.openAccessibilitySettingsCallCount, 1);
  });

  testWidgets('accessibility enabled but not running shows as stalled', (
    tester,
  ) async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        accessibilityRunning: false,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
        child: themedApp(home: const PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Acessibilidade: parada'), findsOneWidget);
    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    expect(fakeRepo.openAccessibilitySettingsCallCount, 1);
  });

  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('with every permission pending on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionsRepositoryProvider.overrideWithValue(
                FakePermissionsRepository(
                  status: const PermissionStatus(
                    accessibilityEnabled: false,
                    batteryOptimizationIgnored: false,
                    autostartAcknowledged: false,
                  ),
                ),
              ),
            ],
            child: themedApp(home: const PermissionsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });
}
