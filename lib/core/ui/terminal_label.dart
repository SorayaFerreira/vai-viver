import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// A shell-prompt style section label, e.g. `~/vaiviver $ status`.
/// Decorative, so screen readers skip it.
class TerminalLabel extends StatelessWidget {
  const TerminalLabel(this.command, {super.key});

  final String command;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          style: AppTypography.mono.copyWith(color: scheme.onSurfaceVariant),
          children: [
            TextSpan(
              text: '~/vaiviver',
              style: TextStyle(color: scheme.primary),
            ),
            const TextSpan(text: ' \$ '),
            TextSpan(
              text: command,
              style: TextStyle(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
