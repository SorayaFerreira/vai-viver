import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/permission_status.dart';

void main() {
  test('enabled but not running is "stalled" and not all granted', () {
    const status = PermissionStatus(
      accessibilityEnabled: true,
      accessibilityRunning: false,
      batteryOptimizationIgnored: true,
      autostartAcknowledged: true,
    );

    expect(status.accessibilityStalled, isTrue);
    expect(status.allGranted, isFalse);
  });

  test('disabled is pending, not stalled', () {
    const status = PermissionStatus(
      accessibilityEnabled: false,
      accessibilityRunning: false,
      batteryOptimizationIgnored: true,
      autostartAcknowledged: true,
    );

    expect(status.accessibilityStalled, isFalse);
  });

  test('enabled and running counts as granted', () {
    const status = PermissionStatus(
      accessibilityEnabled: true,
      accessibilityRunning: true,
      batteryOptimizationIgnored: true,
      autostartAcknowledged: true,
    );

    expect(status.allGranted, isTrue);
  });
}
