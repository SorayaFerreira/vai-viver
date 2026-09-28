import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/permission_status.dart';
import 'permissions_view_model.dart';

class AccessibilityStatusTile extends ConsumerWidget {
  const AccessibilityStatusTile({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        status.accessibilityEnabled ? Icons.check_circle : Icons.error_outline,
      ),
      title: Text(
        'Acessibilidade: ${status.accessibilityEnabled ? "ativada" : "pendente"}',
      ),
      subtitle: const Text(
        'Necessária para detectar Reels e medir a rolagem do Feed',
      ),
      trailing: status.accessibilityEnabled
          ? null
          : TextButton(
              onPressed: () => ref
                  .read(permissionsViewModelProvider.notifier)
                  .openAccessibilitySettings(),
              child: const Text('Abrir'),
            ),
    );
  }
}
