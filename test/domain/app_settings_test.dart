// test/domain/app_settings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/app_settings.dart';

void main() {
  test('copyWith overrides only the given fields', () {
    const original = AppSettings.defaults;

    final updated = original.copyWith(scrollLimitMinutes: 5);

    expect(updated.scrollLimitMinutes, 5);
    expect(updated.reelsBlockEnabled, original.reelsBlockEnabled);
    expect(updated.scrollLimitEnabled, original.scrollLimitEnabled);
  });
}
