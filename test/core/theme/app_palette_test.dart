import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/theme/app_palette.dart';

/// WCAG 2.x contrast ratio between two opaque colors (1.0 to 21.0).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('contrastRatio: black on white is 21:1', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
  });

  for (final (name, p) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('$name palette meets WCAG AA', () {
      // Text and icons: at least 4.5:1.
      final textPairs = <String, (Color, Color)>{
        'onSurface on background': (p.onSurface, p.background),
        'onSurface on surface': (p.onSurface, p.surface),
        'onSurfaceVariant on background': (p.onSurfaceVariant, p.background),
        'onSurfaceVariant on surface': (p.onSurfaceVariant, p.surface),
        'primary on background': (p.primary, p.background),
        'primary on surface': (p.primary, p.surface),
        'onPrimary on primary': (p.onPrimary, p.primary),
        'onPrimary on gradientStart': (p.onPrimary, p.gradientStart),
        'onPrimary on gradientEnd': (p.onPrimary, p.gradientEnd),
        'onPrimaryContainer on primaryContainer': (
          p.onPrimaryContainer,
          p.primaryContainer,
        ),
        'success on successContainer': (p.success, p.successContainer),
        'warning on warningContainer': (p.warning, p.warningContainer),
        'error on surface': (p.error, p.surface),
        'onError on error': (p.onError, p.error),
      };
      for (final MapEntry(key: pair, value: (fg, bg)) in textPairs.entries) {
        test('text: $pair >= 4.5', () {
          expect(fg.a, 1.0, reason: 'contrast needs opaque colors');
          expect(bg.a, 1.0, reason: 'contrast needs opaque colors');
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      // Non-text UI (switch/checkbox borders): at least 3:1.
      final uiPairs = <String, (Color, Color)>{
        'outline on background': (p.outline, p.background),
        'outline on surface': (p.outline, p.surface),
      };
      for (final MapEntry(key: pair, value: (fg, bg)) in uiPairs.entries) {
        test('ui: $pair >= 3.0', () {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(3.0));
        });
      }
    });
  }
}
