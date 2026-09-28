import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_bridge.dart';
import '../../data/method_channel_stats_repository.dart';
import '../../domain/models/daily_stats.dart';
import '../../domain/repositories/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return MethodChannelStatsRepository(NativeBridge());
});

class StatsViewModel extends AsyncNotifier<DailyStats> {
  @override
  Future<DailyStats> build() {
    return ref.watch(statsRepositoryProvider).getTodayStats();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(statsRepositoryProvider).getTodayStats(),
    );
  }
}

final statsViewModelProvider =
    AsyncNotifierProvider<StatsViewModel, DailyStats>(StatsViewModel.new);
