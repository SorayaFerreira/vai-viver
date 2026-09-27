import '../models/permission_status.dart';

abstract class PermissionsRepository {
  Future<PermissionStatus> getStatus();
  Future<void> setAutostartAcknowledged(bool value);
  Future<void> openAccessibilitySettings();
  Future<void> openBatteryOptimizationSettings();
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete(bool value);
}
