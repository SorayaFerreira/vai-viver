import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/feed_limit_steps.dart';
import 'settings_view_model.dart';

class AppSettingsForm extends ConsumerWidget {
  const AppSettingsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsViewModelProvider);

    return settingsAsync.when(
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('reels-block-switch'),
            title: const Text('Bloquear aba Reels'),
            value: settings.reelsBlockEnabled,
            onChanged: (value) => ref
                .read(settingsViewModelProvider.notifier)
                .setReelsBlockEnabled(value),
          ),
          SwitchListTile(
            key: const Key('feed-limit-switch'),
            title: const Text('Limite diário no Feed'),
            value: settings.feedLimitEnabled,
            onChanged: (value) => ref
                .read(settingsViewModelProvider.notifier)
                .setFeedLimitEnabled(value),
          ),
          _MinutesStepper(
            minutes: settings.feedLimitMinutes,
            enabled: settings.feedLimitEnabled,
            onChanged: (minutes) => ref
                .read(settingsViewModelProvider.notifier)
                .setFeedLimitMinutes(minutes),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Erro ao carregar configurações: $err'),
    );
  }
}

/// "Minutos por dia no Feed" with −/+ buttons (steps in feed_limit_steps.dart).
/// A Row with an Expanded label (not a ListTile trailing) so the label wraps
/// under large fonts instead of fighting the buttons for width.
class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({
    required this.minutes,
    required this.enabled,
    required this.onChanged,
  });

  final int minutes;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Minutos por dia no Feed',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: enabled
                    ? null
                    : scheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
          IconButton.outlined(
            key: const Key('feed-limit-decrement'),
            icon: const Icon(Icons.remove),
            onPressed: enabled && minutes > 1
                ? () => onChanged(previousFeedLimit(minutes))
                : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: Text(
              '$minutes',
              textAlign: TextAlign.center,
              style: AppTypography.mono.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: scheme.primary,
              ),
            ),
          ),
          IconButton.outlined(
            key: const Key('feed-limit-increment'),
            icon: const Icon(Icons.add),
            onPressed: enabled ? () => onChanged(nextFeedLimit(minutes)) : null,
          ),
        ],
      ),
    );
  }
}
