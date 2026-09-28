import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'gradient_text.dart';

/// A big thin gradient number with a mono caption. Screen readers hear it as
/// one sentence ("Reels bloqueados hoje: 4"), and tests find it by that label.
class StatValue extends StatelessWidget {
  const StatValue({
    super.key,
    required this.value,
    required this.label,
    this.unit,
  });

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      container: true,
      label: unit == null ? '$label: $value' : '$label: $value $unit',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // A Wrap, not a Row: with large fonts a long unit ("de 20 min")
          // drops below the number instead of overflowing the card.
          Wrap(
            spacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              GradientText(value, style: theme.textTheme.displaySmall),
              if (unit != null)
                Text(
                  unit!,
                  style: theme.textTheme.titleMedium?.copyWith(color: muted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.mono.copyWith(color: muted)),
        ],
      ),
    );
  }
}
