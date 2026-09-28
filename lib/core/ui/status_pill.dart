import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/vaiviver_tokens.dart';

enum PillTone { success, warning }

/// Small rounded-full status tag (krython's `rounded-full px-2.5 py-0.5`).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, foreground) = switch (tone) {
      PillTone.success => (tokens.successContainer, tokens.success),
      PillTone.warning => (tokens.warningContainer, tokens.warning),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: background,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          label,
          style: AppTypography.mono.copyWith(
            color: foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
