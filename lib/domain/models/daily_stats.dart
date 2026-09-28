class DailyStats {
  const DailyStats({
    required this.reelsBlockedCount,
    required this.feedSecondsToday,
    required this.feedBlockedCount,
  });

  final int reelsBlockedCount;
  final int feedSecondsToday;
  final int feedBlockedCount;

  static const empty = DailyStats(
    reelsBlockedCount: 0,
    feedSecondsToday: 0,
    feedBlockedCount: 0,
  );
}
