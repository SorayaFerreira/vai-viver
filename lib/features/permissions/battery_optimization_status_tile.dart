import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permission_card.dart';
import 'permissions_view_model.dart';

class BatteryOptimizationStatusTile extends ConsumerWidget {
  const BatteryOptimizationStatusTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionCard(
      title: 'Otimização de bateria',
      granted: status.batteryOptimizationIgnored,
      grantedLabel: 'isenta',
      explanation:
          'Sem isso o Android pode encerrar o VaiViver em segundo plano.',
      action: status.batteryOptimizationIgnored
          ? null
          : FilledButton.tonal(
              onPressed: () => ref
                  .read(permissionsViewModelProvider.notifier)
                  .openBatteryOptimizationSettings(),
              child: const Text('Pedir isenção'),
            ),
    );
  }
}
