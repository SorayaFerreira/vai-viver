import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/permissions/permissions_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';

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
        child: const MaterialApp(home: PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acessibilidade: ativada'), findsOneWidget);
    expect(find.text('Otimização de bateria: pendente'), findsOneWidget);
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
        child: const MaterialApp(home: PermissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('autostart-ack-checkbox')));
    await tester.pumpAndSettle();

    expect(fakeRepo.status.autostartAcknowledged, true);
  });
}
