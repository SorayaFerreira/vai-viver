import 'package:flutter/material.dart';

/// Raw color values of the VaiViver design system, one instance per
/// brightness. Inspired by krython.com: cyan-blue primary, indigo/violet
/// accents, near-white (light) or near-black bluish (dark) backgrounds.
///
/// This is the only file that holds hex values. Widgets never read it
/// directly: AppTheme maps it into ColorScheme + VaiViverTokens.
@immutable
class AppPalette {
  const AppPalette._({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.onTertiary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.error,
    required this.onError,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.glassFill,
    required this.glassBorder,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.gridLine,
  });

  final Brightness brightness;

  // Surfaces and text.
  final Color background;
  final Color surface;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;

  // Brand.
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color onTertiary;
  final Color gradientStart;
  final Color gradientEnd;

  // Status.
  final Color error;
  final Color onError;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;

  // Ambient effects (translucent on purpose).
  final Color glassFill;
  final Color glassBorder;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color gridLine;

  static const light = AppPalette._(
    brightness: Brightness.light,
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFE5E7EB),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF4B5563),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFFE4E4E7),
    // krython's #2B95D3 only reaches 3.3:1 on white; this darker cyan
    // passes AA for text. The site's cyan survives in the glows.
    primary: Color(0xFF1B78B0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF3730A3),
    secondary: Color(0xFF4F46E5),
    onSecondary: Color(0xFFFFFFFF),
    tertiary: Color(0xFF7C3AED),
    onTertiary: Color(0xFFFFFFFF),
    gradientStart: Color(0xFF1B78B0),
    gradientEnd: Color(0xFF4F46E5),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF047857),
    successContainer: Color(0xFFD1FAE5),
    warning: Color(0xFF92400E),
    warningContainer: Color(0xFFFEF3C7),
    glassFill: Color(0xB8FFFFFF),
    glassBorder: Color(0x1A111827),
    glowPrimary: Color(0x2E00B4FF),
    glowSecondary: Color(0x248B5CF6),
    gridLine: Color(0x0F00B4DC),
  );

  static const dark = AppPalette._(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A10),
    surface: Color(0xFF0F0F17),
    surfaceContainerHighest: Color(0xFF27272F),
    onSurface: Color(0xFFFAFAFA),
    onSurfaceVariant: Color(0xFFBCBCC2),
    outline: Color(0xFF8B8B94),
    outlineVariant: Color(0xFF313135),
    primary: Color(0xFF51D0FA),
    onPrimary: Color(0xFF0A0A10),
    primaryContainer: Color(0xFF1E1B4B),
    onPrimaryContainer: Color(0xFFC7D2FE),
    secondary: Color(0xFF818CF8),
    onSecondary: Color(0xFF0A0A10),
    tertiary: Color(0xFFC084FC),
    onTertiary: Color(0xFF0A0A10),
    gradientStart: Color(0xFF22D3EE),
    gradientEnd: Color(0xFF818CF8),
    error: Color(0xFFF87171),
    onError: Color(0xFF0A0A10),
    success: Color(0xFF34D399),
    successContainer: Color(0xFF064E3B),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF451A03),
    glassFill: Color(0x80111827),
    glassBorder: Color(0x1FFFFFFF),
    glowPrimary: Color(0x2600D2FF),
    glowSecondary: Color(0x26C084FC),
    gridLine: Color(0x0A20E0FF),
  );
}
