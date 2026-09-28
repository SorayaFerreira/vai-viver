import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Design tokens Material's ColorScheme has no slot for: status colors, the
/// glass/glow/grid ambient effects and the brand gradient.
///
/// Registered as a ThemeExtension so widgets read it from the theme
/// (`context.tokens`) and it animates with the theme: when the system
/// switches light <-> dark, MaterialApp tweens ThemeData and calls [lerp].
@immutable
class VaiViverTokens extends ThemeExtension<VaiViverTokens> {
  const VaiViverTokens({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.glassFill,
    required this.glassBorder,
    required this.glassBlur,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.gridLine,
    required this.brandGradient,
  });

  factory VaiViverTokens.fromPalette(AppPalette p) => VaiViverTokens(
    success: p.success,
    successContainer: p.successContainer,
    warning: p.warning,
    warningContainer: p.warningContainer,
    glassFill: p.glassFill,
    glassBorder: p.glassBorder,
    glassBlur: 16,
    glowPrimary: p.glowPrimary,
    glowSecondary: p.glowSecondary,
    gridLine: p.gridLine,
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [p.gradientStart, p.gradientEnd],
    ),
  );

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color glassFill;
  final Color glassBorder;

  /// Backdrop blur sigma, in logical pixels.
  final double glassBlur;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color gridLine;
  final LinearGradient brandGradient;

  @override
  VaiViverTokens copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? glassFill,
    Color? glassBorder,
    double? glassBlur,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? gridLine,
    LinearGradient? brandGradient,
  }) => VaiViverTokens(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    glassFill: glassFill ?? this.glassFill,
    glassBorder: glassBorder ?? this.glassBorder,
    glassBlur: glassBlur ?? this.glassBlur,
    glowPrimary: glowPrimary ?? this.glowPrimary,
    glowSecondary: glowSecondary ?? this.glowSecondary,
    gridLine: gridLine ?? this.gridLine,
    brandGradient: brandGradient ?? this.brandGradient,
  );

  @override
  VaiViverTokens lerp(covariant VaiViverTokens? other, double t) {
    if (other == null) return this;
    return VaiViverTokens(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t)!,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      brandGradient: LinearGradient.lerp(
        brandGradient,
        other.brandGradient,
        t,
      )!,
    );
  }
}

extension VaiViverThemeContext on BuildContext {
  /// The VaiViver tokens of the nearest theme.
  VaiViverTokens get tokens {
    final tokens = Theme.of(this).extension<VaiViverTokens>();
    assert(
      tokens != null,
      'VaiViverTokens missing from the theme: build the MaterialApp with '
      'AppTheme.light()/AppTheme.dark() (in tests, use themedApp()).',
    );
    return tokens!;
  }
}
