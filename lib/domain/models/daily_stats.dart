class DailyStats {
  const DailyStats({
    required this.reelsBlockedCount,
    required this.scrollSecondsSaved,
  });

  final int reelsBlockedCount;
  final int scrollSecondsSaved;

  static const empty = DailyStats(reelsBlockedCount: 0, scrollSecondsSaved: 0);
}
