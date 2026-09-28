import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/domain/repositories/stats_repository.dart';

class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository([this.stats = DailyStats.empty]);

  DailyStats stats;

  /// When non-null, [getTodayStats] throws this instead of returning [stats].
  Object? error;

  @override
  Future<DailyStats> getTodayStats() async {
    if (error != null) throw error!;
    return stats;
  }
}
