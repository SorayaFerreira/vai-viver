import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/native_bridge.dart';
import 'package:vaiviver/data/method_channel_permissions_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.sorayaferreira.vaiviver/native');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getStatus calls the native method and parses the response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getPermissionStatus');
      return {
        'accessibilityEnabled': true,
        'batteryOptimizationIgnored': false,
        'autostartAcknowledged': true,
      };
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    final status = await repository.getStatus();

    expect(status.accessibilityEnabled, true);
    expect(status.batteryOptimizationIgnored, false);
    expect(status.autostartAcknowledged, true);
  });

  test('setAutostartAcknowledged sends the value as an argument', () async {
    Map<Object?, Object?>? receivedArgs;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'setAutostartAcknowledged');
      receivedArgs = call.arguments as Map<Object?, Object?>;
      return null;
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    await repository.setAutostartAcknowledged(true);

    expect(receivedArgs!['value'], true);
  });

  test('openAccessibilitySettings calls the native method', () async {
    String? calledMethod;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calledMethod = call.method;
      return null;
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    await repository.openAccessibilitySettings();

    expect(calledMethod, 'openAccessibilitySettings');
  });

  test('openBatteryOptimizationSettings calls the native method', () async {
    String? calledMethod;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calledMethod = call.method;
      return null;
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    await repository.openBatteryOptimizationSettings();

    expect(calledMethod, 'openBatteryOptimizationSettings');
  });

  test('isOnboardingComplete calls the native method and parses the response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getOnboardingComplete');
      return true;
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    final result = await repository.isOnboardingComplete();

    expect(result, true);
  });

  test('isOnboardingComplete defaults to false when native returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return null;
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    final result = await repository.isOnboardingComplete();

    expect(result, false);
  });

  test('setOnboardingComplete sends the value as an argument', () async {
    Map<Object?, Object?>? receivedArgs;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'setOnboardingComplete');
      receivedArgs = call.arguments as Map<Object?, Object?>;
      return null;
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    await repository.setOnboardingComplete(false);

    expect(receivedArgs!['value'], false);
  });

  test('a platform failure propagates as a PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    final repository = MethodChannelPermissionsRepository(NativeBridge(channel: channel));

    expect(() => repository.getStatus(), throwsA(isA<PlatformException>()));
  });
}
