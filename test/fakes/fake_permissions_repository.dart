import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/domain/repositories/permissions_repository.dart';

class FakePermissionsRepository implements PermissionsRepository {
  FakePermissionsRepository({
    this.status = const PermissionStatus(
      accessibilityEnabled: true,
      batteryOptimizationIgnored: true,
      autostartAcknowledged: true,
    ),
    this._onboardingComplete = true,
  });

  PermissionStatus status;
  bool _onboardingComplete;
  int openAccessibilitySettingsCallCount = 0;
  int openBatteryOptimizationSettingsCallCount = 0;
  int setOnboardingCompleteCallCount = 0;

  /// When non-null, [getStatus] throws this instead of returning [status].
  Object? getStatusError;

  /// When non-null, [setOnboardingComplete] throws this (after counting the call).
  Object? setOnboardingCompleteError;

  @override
  Future<PermissionStatus> getStatus() async {
    if (getStatusError != null) throw getStatusError!;
    return status;
  }

  @override
  Future<void> setAutostartAcknowledged(bool value) async {
    status = PermissionStatus(
      accessibilityEnabled: status.accessibilityEnabled,
      batteryOptimizationIgnored: status.batteryOptimizationIgnored,
      autostartAcknowledged: value,
    );
  }

  @override
  Future<void> openAccessibilitySettings() async {
    openAccessibilitySettingsCallCount++;
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    openBatteryOptimizationSettingsCallCount++;
  }

  @override
  Future<bool> isOnboardingComplete() async => _onboardingComplete;

  @override
  Future<void> setOnboardingComplete(bool value) async {
    setOnboardingCompleteCallCount++;
    if (setOnboardingCompleteError != null) throw setOnboardingCompleteError!;
    _onboardingComplete = value;
  }
}
