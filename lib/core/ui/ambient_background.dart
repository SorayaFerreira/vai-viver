import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/vaiviver_tokens.dart';

/// The app's backdrop: theme background, a faint "matrix" grid and two soft
/// glows (cyan top-right, violet bottom-left). GlassCards blur this, which
/// is what makes the glass visible — over a flat color it would look like a
/// plain grey card. Static on purpose: no decorative motion.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GridPainter(
                  color: tokens.gridLine,
                  spacing: AppSpacing.xxl,
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: tokens.glowPrimary, diameter: 320),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(color: tokens.glowSecondary, diameter: 360),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}
