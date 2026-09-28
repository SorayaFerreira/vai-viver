import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permission_card.dart';
import 'permissions_view_model.dart';

class AutostartAckTile extends ConsumerWidget {
  const AutostartAckTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionCard(
      title: 'Autostart (Xiaomi/MIUI)',
      granted: status.autostartAcknowledged,
      grantedLabel: 'confirmado',
      explanation:
          'Sem o Autostart, o MIUI pode não religar o VaiViver depois que o '
          'celular reinicia. Não dá pra verificar isso automaticamente — '
          'ative em:',
      detail:
          'Configurações > Apps > Gerenciar apps > VaiViver > Autostart\n'
          'ou App Segurança > Permissões > Autostart',
      action: CheckboxListTile(
        key: const Key('autostart-ack-checkbox'),
        value: status.autostartAcknowledged,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Já fiz isso'),
        onChanged: (value) {
          if (value == true) {
            ref
                .read(permissionsViewModelProvider.notifier)
                .acknowledgeAutostart();
          }
        },
      ),
    );
  }
}
