class AppSettings {
  const AppSettings({
    required this.reelsBlockEnabled,
    required this.feedLimitEnabled,
    required this.feedLimitMinutes,
  });

  final bool reelsBlockEnabled;
  final bool feedLimitEnabled;
  final int feedLimitMinutes;

  static const defaults = AppSettings(
    reelsBlockEnabled: true,
    feedLimitEnabled: true,
    feedLimitMinutes: 20,
  );

  AppSettings copyWith({
    bool? reelsBlockEnabled,
    bool? feedLimitEnabled,
    int? feedLimitMinutes,
  }) {
    return AppSettings(
      reelsBlockEnabled: reelsBlockEnabled ?? this.reelsBlockEnabled,
      feedLimitEnabled: feedLimitEnabled ?? this.feedLimitEnabled,
      feedLimitMinutes: feedLimitMinutes ?? this.feedLimitMinutes,
    );
  }
}
