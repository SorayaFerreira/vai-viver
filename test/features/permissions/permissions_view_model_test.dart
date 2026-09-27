import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';

void main() {
  test('acknowledgeAutostart persists and refreshes status', () async {
    final fakeRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: true,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(permissionsViewModelProvider.future);
    await container.read(permissionsViewModelProvider.notifier).acknowledgeAutostart();

    expect(container.read(permissionsViewModelProvider).value!.autostartAcknowledged, true);
  });

  test('openAccessibilitySettings delegates to the repository', () async {
    final fakeRepo = FakePermissionsRepository();
    final container = ProviderContainer(
      overrides: [permissionsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(permissionsViewModelProvider.future);
    await container.read(permissionsViewModelProvider.notifier).openAccessibilitySettings();

    expect(fakeRepo.openAccessibilitySettingsCallCount, 1);
  });
}
