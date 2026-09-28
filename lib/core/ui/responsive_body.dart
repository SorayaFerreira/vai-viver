import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Lays out a screen's content so it never runs off the screen:
/// - stays inside the system bars (the app draws edge-to-edge);
/// - scrolls when taller than the viewport (large system fonts, small
///   screens, landscape) instead of overflowing or clipping;
/// - caps line length at [maxContentWidth] on wide screens;
/// - pins an optional [bottomAction] (e.g. "Próximo") above the nav bar.
/// Short content is centered vertically (the app's screens hold little, and
/// top-aligned they looked empty); once it no longer fits, it scrolls.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.bottomAction});

  static const maxContentWidth = 560.0;
  static const _padding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.xl,
  );

  final Widget child;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(
                  constraints.maxWidth - _padding.horizontal,
                  maxContentWidth,
                );
                final minHeight = math.max(
                  0.0,
                  constraints.maxHeight - _padding.vertical,
                );
                return SingleChildScrollView(
                  padding: _padding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: width)
                          .copyWith(minHeight: minHeight),
                      // A Column rather than Center: it centers vertically
                      // but keeps the child at full width (cards stretch).
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [child],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (bottomAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: SizedBox(width: double.infinity, child: bottomAction),
              ),
            ),
        ],
      ),
    );
  }
}
