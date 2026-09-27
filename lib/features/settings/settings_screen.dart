import 'package:flutter/material.dart';

import 'app_settings_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSettingsForm(),
          const Divider(height: 32),
          ListTile(
            title: const Text('Verificar permissões'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/permissions'),
          ),
        ],
      ),
    );
  }
}
