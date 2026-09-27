import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accessibility_status_tile.dart';
import 'autostart_ack_tile.dart';
import 'battery_optimization_status_tile.dart';
import 'permissions_view_model.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(permissionsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Status das Permissões')),
      body: statusAsync.when(
        data: (status) => ListView(
          children: [
            AccessibilityStatusTile(status: status),
            BatteryOptimizationStatusTile(status: status),
            AutostartAckTile(status: status),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar permissões: $err')),
      ),
    );
  }
}
