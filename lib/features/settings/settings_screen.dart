import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_screen.dart';
import '../../core/ui/glass_card.dart';
import '../../core/ui/responsive_body.dart';
import '../../core/ui/terminal_label.dart';
import 'app_settings_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScreen(
      title: 'Configurações',
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TerminalLabel('config'),
            const SizedBox(height: AppSpacing.lg),
            const GlassCard(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppSettingsForm(),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              onTap: () => Navigator.of(context).pushNamed('/permissions'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verificar permissões',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
