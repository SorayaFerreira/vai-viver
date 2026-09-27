import '../core/native_bridge.dart';
import '../domain/models/permission_status.dart';
import '../domain/repositories/permissions_repository.dart';

class MethodChannelPermissionsRepository implements PermissionsRepository {
  MethodChannelPermissionsRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<PermissionStatus> getStatus() async {
    final map = await _bridge.channel.invokeMapMethod<String, Object?>('getPermissionStatus');
    return PermissionStatus(
      accessibilityEnabled: map!['accessibilityEnabled'] as bool,
      batteryOptimizationIgnored: map['batteryOptimizationIgnored'] as bool,
      autostartAcknowledged: map['autostartAcknowledged'] as bool,
    );
  }

  @override
  Future<void> setAutostartAcknowledged(bool value) {
    return _bridge.channel.invokeMethod('setAutostartAcknowledged', {'value': value});
  }

  @override
  Future<void> openAccessibilitySettings() {
    return _bridge.channel.invokeMethod('openAccessibilitySettings');
  }

  @override
  Future<void> openBatteryOptimizationSettings() {
    return _bridge.channel.invokeMethod('openBatteryOptimizationSettings');
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final value = await _bridge.channel.invokeMethod<bool>('getOnboardingComplete');
    return value ?? false;
  }

  @override
  Future<void> setOnboardingComplete(bool value) {
    return _bridge.channel.invokeMethod('setOnboardingComplete', {'value': value});
  }
}
