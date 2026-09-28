import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/native_bridge.dart';
import 'package:vaiviver/data/method_channel_settings_repository.dart';
import 'package:vaiviver/domain/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.sorayaferreira.vaiviver/native');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getSettings calls the native method and parses the response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getSettings');
          return {
            'reelsBlockEnabled': true,
            'feedLimitEnabled': false,
            'feedLimitMinutes': 3,
          };
        });
    final repository = MethodChannelSettingsRepository(
      NativeBridge(channel: channel),
    );

    final settings = await repository.getSettings();

    expect(settings.reelsBlockEnabled, true);
    expect(settings.feedLimitEnabled, false);
    expect(settings.feedLimitMinutes, 3);
  });

  test('saveSettings sends the settings as arguments', () async {
    Map<Object?, Object?>? receivedArgs;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedArgs = call.arguments as Map<Object?, Object?>;
          return null;
        });
    final repository = MethodChannelSettingsRepository(
      NativeBridge(channel: channel),
    );

    await repository.saveSettings(
      const AppSettings(
        reelsBlockEnabled: false,
        feedLimitEnabled: true,
        feedLimitMinutes: 9,
      ),
    );

    expect(receivedArgs!['feedLimitMinutes'], 9);
    expect(receivedArgs!['reelsBlockEnabled'], false);
  });

  test('a platform failure propagates as a PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });
    final repository = MethodChannelSettingsRepository(
      NativeBridge(channel: channel),
    );

    expect(() => repository.getSettings(), throwsA(isA<PlatformException>()));
  });
}
