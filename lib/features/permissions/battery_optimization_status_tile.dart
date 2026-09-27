import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permissions_view_model.dart';

class BatteryOptimizationStatusTile extends ConsumerWidget {
  const BatteryOptimizationStatusTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(status.batteryOptimizationIgnored ? Icons.check_circle : Icons.error_outline),
      title: Text(
        'Otimização de bateria: ${status.batteryOptimizationIgnored ? "isenta" : "pendente"}',
      ),
      subtitle: const Text('Sem isso o Android pode encerrar o VaiViver em segundo plano'),
      trailing: status.batteryOptimizationIgnored
          ? null
          : TextButton(
              onPressed: () =>
                  ref.read(permissionsViewModelProvider.notifier).openBatteryOptimizationSettings(),
              child: const Text('Abrir'),
            ),
    );
  }
}
