import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_view_model.dart';

class AppSettingsForm extends ConsumerWidget {
  const AppSettingsForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsViewModelProvider);

    return settingsAsync.when(
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('reels-block-switch'),
            title: const Text('Bloquear aba Reels'),
            value: settings.reelsBlockEnabled,
            onChanged: (value) => ref
                .read(settingsViewModelProvider.notifier)
                .setReelsBlockEnabled(value),
          ),
          SwitchListTile(
            key: const Key('scroll-limit-switch'),
            title: const Text('Limite de scroll no Feed'),
            value: settings.scrollLimitEnabled,
            onChanged: (value) => ref
                .read(settingsViewModelProvider.notifier)
                .setScrollLimitEnabled(value),
          ),
          ListTile(
            title: const Text('Limite de scroll (minutos)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('scroll-limit-decrement'),
                  icon: const Icon(Icons.remove),
                  onPressed:
                      settings.scrollLimitEnabled &&
                          settings.scrollLimitMinutes > 1
                      ? () => ref
                            .read(settingsViewModelProvider.notifier)
                            .setScrollLimitMinutes(
                              settings.scrollLimitMinutes - 1,
                            )
                      : null,
                ),
                Text('${settings.scrollLimitMinutes}'),
                IconButton(
                  key: const Key('scroll-limit-increment'),
                  icon: const Icon(Icons.add),
                  onPressed: settings.scrollLimitEnabled
                      ? () => ref
                            .read(settingsViewModelProvider.notifier)
                            .setScrollLimitMinutes(
                              settings.scrollLimitMinutes + 1,
                            )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Erro ao carregar configurações: $err'),
    );
  }
}
