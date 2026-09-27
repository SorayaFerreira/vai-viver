import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permissions_view_model.dart';

class AutostartAckTile extends ConsumerWidget {
  const AutostartAckTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      key: const Key('autostart-ack-checkbox'),
      value: status.autostartAcknowledged,
      title: const Text('Autostart (Xiaomi/MIUI) habilitado'),
      subtitle: const Text(
        'Configurações > Apps > Gerenciar apps > VaiViver > Autostart, ou '
        'App Segurança > Permissões > Autostart',
      ),
      onChanged: (value) {
        if (value == true) {
          ref.read(permissionsViewModelProvider.notifier).acknowledgeAutostart();
        }
      },
    );
  }
}
