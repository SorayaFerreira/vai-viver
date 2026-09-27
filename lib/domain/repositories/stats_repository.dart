import '../models/daily_stats.dart';

abstract class StatsRepository {
  Future<DailyStats> getTodayStats();
}
