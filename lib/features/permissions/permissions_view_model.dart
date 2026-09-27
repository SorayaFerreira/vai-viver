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
    state = AsyncData(await ref.read(permissionsRepositoryProvider).getStatus());
  }

  Future<void> acknowledgeAutostart() async {
    await ref.read(permissionsRepositoryProvider).setAutostartAcknowledged(true);
    await refresh();
  }

  Future<void> openAccessibilitySettings() {
    return ref.read(permissionsRepositoryProvider).openAccessibilitySettings();
  }

  Future<void> openBatteryOptimizationSettings() {
    return ref.read(permissionsRepositoryProvider).openBatteryOptimizationSettings();
  }
}

final permissionsViewModelProvider =
    AsyncNotifierProvider<PermissionsViewModel, PermissionStatus>(PermissionsViewModel.new);
