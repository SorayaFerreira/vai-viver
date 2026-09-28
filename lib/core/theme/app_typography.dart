import 'package:flutter/material.dart';

/// Font families and the text-style tweaks that give the app krython.com's
/// look: thin large type, bold titles, airy body text, mono accents.
abstract final class AppTypography {
  static const sans = 'Satoshi';
  static const monoFamily = 'JetBrainsMono';

  /// Terminal-style labels (TerminalLabel, StatusPill, stat captions).
  /// Color is applied where it is used.
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static TextTheme refine(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w300,
      letterSpacing: -1,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      height: 1.15,
    ),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w500),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
    labelLarge: base.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
  );
}
