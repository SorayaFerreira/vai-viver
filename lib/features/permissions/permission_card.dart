import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/glass_card.dart';
import '../../core/ui/status_pill.dart';

/// One permission: title + granted/pending pill, a free-flowing explanation
/// (it may wrap to many lines — nothing here has a fixed height), an optional
/// monospace [detail] such as a settings path, and the fix-it [action] below
/// the text at full width instead of squeezed beside it.
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.title,
    required this.granted,
    required this.grantedLabel,
    required this.explanation,
    this.pendingLabel = defaultPendingLabel,
    this.detail,
    this.action,
  });

  static const defaultPendingLabel = 'pendente';

  final String title;
  final bool granted;
  final String grantedLabel;

  /// Pill text when not granted (e.g. 'parada' for a stalled service).
  final String pendingLabel;
  final String explanation;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = granted ? grantedLabel : pendingLabel;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: '$title: $statusLabel',
            excludeSemantics: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                StatusPill(
                  label: statusLabel,
                  tone: granted ? PillTone.success : PillTone.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail!,
              style: AppTypography.mono.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
