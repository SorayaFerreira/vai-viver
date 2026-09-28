import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/native_bridge.dart';
import 'package:vaiviver/data/method_channel_stats_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.sorayaferreira.vaiviver/native');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'getTodayStats calls the native method and parses the response',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getTodayStats');
            return {
              'reelsBlockedCount': 7,
              'feedSecondsToday': 120,
              'feedBlockedCount': 2,
            };
          });
      final repository = MethodChannelStatsRepository(
        NativeBridge(channel: channel),
      );

      final stats = await repository.getTodayStats();

      expect(stats.reelsBlockedCount, 7);
      expect(stats.feedSecondsToday, 120);
      expect(stats.feedBlockedCount, 2);
    },
  );

  test('a platform failure propagates as a PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });
    final repository = MethodChannelStatsRepository(
      NativeBridge(channel: channel),
    );

    expect(() => repository.getTodayStats(), throwsA(isA<PlatformException>()));
  });
}
