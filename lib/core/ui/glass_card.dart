import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/vaiviver_tokens.dart';

/// Frosted-glass surface: blurs what is behind it (the AmbientBackground grid
/// and glows), tints it with the glass fill and draws a hairline border.
/// Tappable when [onTap] is set.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadius.card);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.glassBlur,
          sigmaY: tokens.glassBlur,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: radius,
              border: Border.all(color: tokens.glassBorder),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
