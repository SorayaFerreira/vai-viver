import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_screen.dart';
import '../../core/ui/glass_card.dart';
import '../../core/ui/responsive_body.dart';
import '../../core/ui/terminal_label.dart';
import '../home/home_screen.dart';
import '../permissions/accessibility_status_tile.dart';
import '../permissions/autostart_ack_tile.dart';
import '../permissions/battery_optimization_status_tile.dart';
import '../permissions/permissions_view_model.dart';
import '../settings/app_settings_form.dart';
import 'welcome_step.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user grants permissions in system Settings and comes back here.
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsViewModelProvider.notifier).refresh();
    }
  }

  void _goNext() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    try {
      await ref.read(permissionsRepositoryProvider).setOnboardingComplete(true);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao concluir: $err')));
      return;
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(permissionsViewModelProvider);

    return AppScreen(
      body: statusAsync.when(
        data: (status) => PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            WelcomeStep(onNext: _goNext),
            _StepScaffold(
              step: 1,
              onNext: _goNext,
              canAdvance: status.accessibilityEnabled,
              child: AccessibilityStatusTile(status: status),
            ),
            _StepScaffold(
              step: 2,
              onNext: _goNext,
              child: BatteryOptimizationStatusTile(status: status),
            ),
            _StepScaffold(
              step: 3,
              onNext: _goNext,
              child: AutostartAckTile(status: status),
            ),
            _StepScaffold(
              step: 4,
              onNext: _finish,
              buttonLabel: 'Concluir',
              child: const GlassCard(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: AppSettingsForm(),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ResponsiveBody(child: Text('Erro: $err')),
      ),
    );
  }
}

/// One onboarding step: a "setup n/4" prompt, the step's content (scrolls
/// when it doesn't fit) and the advance button pinned above the nav bar.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.step,
    required this.child,
    required this.onNext,
    this.buttonLabel = 'Próximo',
    this.canAdvance = true,
  });

  static const _stepCount = 4;

  final int step;
  final Widget child;
  final VoidCallback onNext;
  final String buttonLabel;
  final bool canAdvance;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody(
      bottomAction: ElevatedButton(
        onPressed: canAdvance ? onNext : null,
        child: Text(buttonLabel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TerminalLabel('setup $step/$_stepCount'),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
