import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Lays out a screen's content so it never runs off the screen:
/// - stays inside the system bars (the app draws edge-to-edge);
/// - scrolls when taller than the viewport (large system fonts, small
///   screens, landscape) instead of overflowing or clipping;
/// - caps line length at [maxContentWidth] on wide screens;
/// - pins an optional [bottomAction] (e.g. "Próximo") above the nav bar.
/// With [centerContent], short content is centered vertically and still
/// scrolls once it no longer fits.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.bottomAction,
    this.centerContent = false,
  });

  static const maxContentWidth = 560.0;
  static const _padding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.xl,
  );

  final Widget child;
  final Widget? bottomAction;
  final bool centerContent;

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
                final minHeight = centerContent
                    ? math.max(0.0, constraints.maxHeight - _padding.vertical)
                    : 0.0;
                return SingleChildScrollView(
                  padding: _padding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: width)
                          .copyWith(minHeight: minHeight),
                      child: centerContent ? Center(child: child) : child,
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
