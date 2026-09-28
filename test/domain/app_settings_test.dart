// test/domain/app_settings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/app_settings.dart';

void main() {
  test('copyWith overrides only the given fields', () {
    const original = AppSettings.defaults;

    final updated = original.copyWith(feedLimitMinutes: 5);

    expect(updated.feedLimitMinutes, 5);
    expect(updated.reelsBlockEnabled, original.reelsBlockEnabled);
    expect(updated.feedLimitEnabled, original.feedLimitEnabled);
    expect(AppSettings.defaults.feedLimitMinutes, 20);
  });
}
