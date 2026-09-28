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
    return PermissionCard(
      title: 'Acessibilidade',
      granted: status.accessibilityEnabled,
      grantedLabel: 'ativada',
      explanation:
          'O VaiViver precisa ler a tela do Instagram pra saber quando você '
          'está na aba Reels ou rolando o Feed — ele nunca lê nada de outros '
          'apps.',
      action: status.accessibilityEnabled
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
