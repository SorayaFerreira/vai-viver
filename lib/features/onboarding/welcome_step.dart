import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/ui/gradient_text.dart';
import '../../core/ui/responsive_body.dart';
import '../../core/ui/terminal_label.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveBody(
      bottomAction: ElevatedButton(
        onPressed: onNext,
        child: const Text('Próximo'),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalLabel('init'),
          const SizedBox(height: AppSpacing.lg),
          GradientText(
            'Bem-vinda ao VaiViver',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'O VaiViver bloqueia a aba Reels do Instagram e limita quanto tempo '
            'você rola o Feed. Para isso, ele precisa de algumas permissões.\n'
            'Vamos te guiar por cada uma! 💫',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
