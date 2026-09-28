import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_screen.dart';
import '../../core/ui/responsive_body.dart';
import '../../core/ui/terminal_label.dart';
import 'accessibility_status_tile.dart';
import 'autostart_ack_tile.dart';
import 'battery_optimization_status_tile.dart';
import 'permissions_view_model.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(permissionsViewModelProvider);

    return AppScreen(
      title: 'Status das Permissões',
      body: statusAsync.when(
        data: (status) => ResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TerminalLabel('check permissions'),
              const SizedBox(height: AppSpacing.lg),
              AccessibilityStatusTile(status: status),
              const SizedBox(height: AppSpacing.md),
              BatteryOptimizationStatusTile(status: status),
              const SizedBox(height: AppSpacing.md),
              AutostartAckTile(status: status),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            ResponsiveBody(child: Text('Erro ao carregar permissões: $err')),
      ),
    );
  }
}
