import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permission_card.dart';
import 'permissions_view_model.dart';

class AccessibilityStatusTile extends ConsumerWidget {
  const AccessibilityStatusTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stalled = status.accessibilityStalled;
    final granted = status.accessibilityEnabled && !stalled;
    return PermissionCard(
      title: 'Acessibilidade',
      granted: granted,
      grantedLabel: 'ativada',
      pendingLabel: stalled ? 'parada' : PermissionCard.defaultPendingLabel,
      explanation: stalled
          ? 'A permissão está ligada, mas o Android parou o serviço do '
                'VaiViver (acontece ao fechar o app nos recentes ou depois de '
                'atualizá-lo). Desligue e ligue o VaiViver em Acessibilidade.'
          : 'O VaiViver precisa ler a tela do Instagram pra saber quando você '
                'está na aba Reels ou rolando o Feed. Ele nunca lê nada de '
                'outros apps.',
      action: granted
          ? null
          : FilledButton.tonal(
              onPressed: () => ref
                  .read(permissionsViewModelProvider.notifier)
                  .openAccessibilitySettings(),
              child: const Text('Abrir configurações'),
            ),
    );
  }
}
