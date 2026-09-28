import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/theme/app_palette.dart';
import 'package:vaiviver/core/theme/app_theme.dart';
import 'package:vaiviver/core/theme/app_typography.dart';
import 'package:vaiviver/core/theme/vaiviver_tokens.dart';

void main() {
  for (final (theme, palette) in [
    (AppTheme.light(), AppPalette.light),
    (AppTheme.dark(), AppPalette.dark),
  ]) {
    final name = palette.brightness.name;

    test('$name: color scheme and background come from the palette', () {
      expect(theme.brightness, palette.brightness);
      expect(theme.colorScheme.primary, palette.primary);
      expect(theme.colorScheme.onSurface, palette.onSurface);
      expect(theme.colorScheme.secondaryContainer, palette.primaryContainer);
      expect(theme.scaffoldBackgroundColor, palette.background);
    });

    test('$name: tokens extension carries the ambient effects', () {
      final tokens = theme.extension<VaiViverTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.glassFill, palette.glassFill);
      expect(tokens.success, palette.success);
      expect(tokens.brandGradient.colors, [
        palette.gradientStart,
        palette.gradientEnd,
      ]);
    });

    test('$name: Satoshi everywhere, thin display type, bold titles', () {
      expect(theme.textTheme.bodyMedium!.fontFamily, AppTypography.sans);
      expect(theme.textTheme.displaySmall!.fontWeight, FontWeight.w300);
      expect(theme.textTheme.headlineMedium!.fontWeight, FontWeight.w300);
      expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w700);
    });
  }

  group('VaiViverTokens.lerp', () {
    final light = VaiViverTokens.fromPalette(AppPalette.light);
    final dark = VaiViverTokens.fromPalette(AppPalette.dark);

    test('t=0 and t=1 return each side', () {
      expect(light.lerp(dark, 0).success, light.success);
      expect(light.lerp(dark, 1).success, dark.success);
      expect(light.lerp(dark, 1).glassFill, dark.glassFill);
      expect(
        light.lerp(dark, 1).brandGradient.colors,
        dark.brandGradient.colors,
      );
    });

    test('null other keeps this', () {
      expect(light.lerp(null, 0.5), same(light));
    });
  });

  testWidgets('enabled ElevatedButton paints the brand gradient; '
      'disabled one does not', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              ElevatedButton(
                key: const Key('on'),
                onPressed: () {},
                child: const Text('on'),
              ),
              const ElevatedButton(
                key: Key('off'),
                onPressed: null,
                child: Text('off'),
              ),
            ],
          ),
        ),
      ),
    );

    Gradient? backgroundGradientOf(String key) {
      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(DecoratedBox),
        ),
      );
      return boxes
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .first
          .gradient;
    }

    final tokens = AppTheme.light().extension<VaiViverTokens>()!;
    expect(backgroundGradientOf('on'), tokens.brandGradient);
    expect(backgroundGradientOf('off'), isNull);
  });
}
