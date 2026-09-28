import '../core/native_bridge.dart';
import '../domain/models/daily_stats.dart';
import '../domain/repositories/stats_repository.dart';

class MethodChannelStatsRepository implements StatsRepository {
  MethodChannelStatsRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<DailyStats> getTodayStats() async {
    final map = await _bridge.channel.invokeMapMethod<String, Object?>(
      'getTodayStats',
    );
    return DailyStats(
      reelsBlockedCount: map!['reelsBlockedCount'] as int,
      scrollSecondsSaved: map['scrollSecondsSaved'] as int,
    );
  }
}
