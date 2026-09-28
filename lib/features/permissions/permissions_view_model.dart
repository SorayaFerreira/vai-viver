import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_bridge.dart';
import '../../data/method_channel_permissions_repository.dart';
import '../../domain/models/permission_status.dart';
import '../../domain/repositories/permissions_repository.dart';

final permissionsRepositoryProvider = Provider<PermissionsRepository>((ref) {
  return MethodChannelPermissionsRepository(NativeBridge());
});

class PermissionsViewModel extends AsyncNotifier<PermissionStatus> {
  @override
  Future<PermissionStatus> build() {
    return ref.watch(permissionsRepositoryProvider).getStatus();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(permissionsRepositoryProvider).getStatus(),
    );
  }

  Future<void> acknowledgeAutostart() async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(permissionsRepositoryProvider);
      await repository.setAutostartAcknowledged(true);
      return repository.getStatus();
    });
  }

  Future<void> openAccessibilitySettings() {
    return ref.read(permissionsRepositoryProvider).openAccessibilitySettings();
  }

  Future<void> openBatteryOptimizationSettings() {
    return ref
        .read(permissionsRepositoryProvider)
        .openBatteryOptimizationSettings();
  }
}

final permissionsViewModelProvider =
    AsyncNotifierProvider<PermissionsViewModel, PermissionStatus>(
      PermissionsViewModel.new,
    );
