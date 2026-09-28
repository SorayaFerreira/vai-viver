import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/daily_stats.dart';
import '../../domain/models/permission_status.dart';
import '../permissions/permissions_view_model.dart';
import '../stats/stats_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsViewModelProvider.notifier).refresh();
      ref.read(statsViewModelProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsViewModelProvider);
    final stats = ref.watch(statsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VaiViver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          permissions.when(
            data: (status) => _PermissionsStatusCard(status: status),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Erro ao carregar permissões: $err'),
          ),
          const SizedBox(height: 16),
          stats.when(
            data: (data) => _StatsCard(stats: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Erro ao carregar estatísticas: $err'),
          ),
        ],
      ),
    );
  }
}

class _PermissionsStatusCard extends StatelessWidget {
  const _PermissionsStatusCard({required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final allGranted = status.allGranted;
    return Card(
      color: allGranted ? Colors.green.shade50 : Colors.orange.shade50,
      child: ListTile(
        leading: Icon(
          allGranted ? Icons.check_circle : Icons.warning,
          color: allGranted ? Colors.green : Colors.orange,
        ),
        title: Text(allGranted ? 'Proteções ativas' : 'Ação necessária'),
        subtitle: allGranted
            ? null
            : const Text('Verifique as permissões pendentes'),
        onTap: () => Navigator.of(context).pushNamed('/permissions'),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    final minutesSaved = (stats.scrollSecondsSaved / 60).floor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reels bloqueados hoje: ${stats.reelsBlockedCount}'),
            Text('Minutos de scroll evitados hoje: $minutesSaved min'),
          ],
        ),
      ),
    );
  }
}
