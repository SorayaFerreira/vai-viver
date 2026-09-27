import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'features/permissions/permissions_screen.dart';
import 'features/permissions/permissions_view_model.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: VaiViverApp()));
}

final onboardingCompleteProvider = FutureProvider<bool>((ref) {
  return ref.watch(permissionsRepositoryProvider).isOnboardingComplete();
});

class VaiViverApp extends StatelessWidget {
  const VaiViverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaiViver',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/permissions': (_) => const PermissionsScreen(),
      },
      home: const AppStartupGate(),
    );
  }
}

class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
    return onboardingComplete.when(
      data: (complete) => complete ? const HomeScreen() : const OnboardingFlowScreen(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro: $err'))),
    );
  }
}
