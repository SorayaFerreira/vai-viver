import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/domain/repositories/stats_repository.dart';

class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository([this.stats = DailyStats.empty]);

  DailyStats stats;

  @override
  Future<DailyStats> getTodayStats() async => stats;
}
