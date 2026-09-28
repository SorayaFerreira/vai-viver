import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_dimens.dart';
import 'app_palette.dart';
import 'app_typography.dart';
import 'vaiviver_tokens.dart';

/// Builds the app's ThemeData from [AppPalette]: palette -> ColorScheme +
/// VaiViverTokens -> component themes. Widgets only ever see the result.
abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  /// Status/navigation bar icons readable over the app background. The bars
  /// themselves stay transparent: the app draws edge-to-edge.
  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return base.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    );
  }

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      // FilledButton.tonal uses these: indigo chips, like krython's tags.
      secondaryContainer: p.primaryContainer,
      onSecondaryContainer: p.onPrimaryContainer,
      tertiary: p.tertiary,
      onTertiary: p.onTertiary,
      error: p.error,
      onError: p.onError,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      surfaceContainerHighest: p.surfaceContainerHighest,
      outline: p.outline,
      outlineVariant: p.outlineVariant,
    );
    final tokens = VaiViverTokens.fromPalette(p);
    final base = ThemeData(colorScheme: scheme, fontFamily: AppTypography.sans);
    final textTheme = AppTypography.refine(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyleFor(p.brightness),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: p.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _gradientButtonStyle(p, tokens, textTheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.outlineVariant,
        space: AppSpacing.xl,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Primary call to action: a pill filled with the brand gradient. Living in
  /// the theme, it reaches every ElevatedButton with no call-site changes.
  /// backgroundBuilder paints over the Material's ink splash, so the pressed
  /// feedback is drawn here as well.
  static ButtonStyle _gradientButtonStyle(
    AppPalette p,
    VaiViverTokens tokens,
    TextTheme textTheme,
  ) {
    return ElevatedButton.styleFrom(
      foregroundColor: p.onPrimary,
      disabledForegroundColor: p.onSurface.withValues(alpha: 0.38),
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      minimumSize: const Size(64, 52),
      shape: const StadiumBorder(),
      textStyle: textTheme.labelLarge,
    ).copyWith(
      backgroundBuilder: (context, states, child) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        return DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            gradient: disabled ? null : tokens.brandGradient,
            color: disabled ? p.onSurface.withValues(alpha: 0.12) : null,
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: pressed
                  ? p.onPrimary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
