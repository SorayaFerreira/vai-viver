import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/vaiviver_tokens.dart';
import '../../core/ui/app_screen.dart';
import '../../core/ui/glass_card.dart';
import '../../core/ui/responsive_body.dart';
import '../../core/ui/stat_value.dart';
import '../../core/ui/terminal_label.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/daily_stats.dart';
import '../../domain/models/permission_status.dart';
import '../permissions/permissions_view_model.dart';
import '../settings/settings_view_model.dart';
import '../stats/stats_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsViewModelProvider.notifier).refresh();
      ref.read(statsViewModelProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsViewModelProvider);
    final stats = ref.watch(statsViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);

    return AppScreen(
      title: 'VaiViver',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configurações',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TerminalLabel('status'),
            const SizedBox(height: AppSpacing.lg),
            permissions.when(
              data: (status) => _PermissionsStatusCard(status: status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erro ao carregar permissões: $err'),
            ),
            const SizedBox(height: AppSpacing.md),
            stats.when(
              data: (data) =>
                  _StatsCard(stats: data, feedLimit: settings.value),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erro ao carregar estatísticas: $err'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsStatusCard extends StatelessWidget {
  const _PermissionsStatusCard({required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final allGranted = status.allGranted;
    final (foreground, background) = allGranted
        ? (tokens.success, tokens.successContainer)
        : (tokens.warning, tokens.warningContainer);
    return GlassCard(
      onTap: () => Navigator.of(context).pushNamed('/permissions'),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                allGranted
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allGranted ? 'Proteções ativas' : 'Ação necessária',
                  style: theme.textTheme.titleMedium,
                ),
                if (!allGranted)
                  Text(
                    'Verifique as permissões pendentes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.feedLimit});

  final DailyStats stats;

  /// Null while settings load; the card then shows plain minutes.
  final AppSettings? feedLimit;

  @override
  Widget build(BuildContext context) {
    final feedMinutes = stats.feedSecondsToday ~/ 60;
    final limit = feedLimit;
    return GlassCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          StatValue(
            value: '$feedMinutes',
            unit: limit != null && limit.feedLimitEnabled
                ? 'de ${limit.feedLimitMinutes} min'
                : 'min',
            label: 'Tempo no Feed hoje',
          ),
          StatValue(
            value: '${stats.reelsBlockedCount}',
            label: 'Reels bloqueados hoje',
          ),
          StatValue(
            value: '${stats.feedBlockedCount}',
            label: 'Saídas forçadas do Feed hoje',
          ),
        ],
      ),
    );
  }
}
