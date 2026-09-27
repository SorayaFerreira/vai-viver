class AppSettings {
  const AppSettings({
    required this.reelsBlockEnabled,
    required this.scrollLimitEnabled,
    required this.scrollLimitMinutes,
  });

  final bool reelsBlockEnabled;
  final bool scrollLimitEnabled;
  final int scrollLimitMinutes;

  static const defaults = AppSettings(
    reelsBlockEnabled: true,
    scrollLimitEnabled: true,
    scrollLimitMinutes: 2,
  );

  AppSettings copyWith({
    bool? reelsBlockEnabled,
    bool? scrollLimitEnabled,
    int? scrollLimitMinutes,
  }) {
    return AppSettings(
      reelsBlockEnabled: reelsBlockEnabled ?? this.reelsBlockEnabled,
      scrollLimitEnabled: scrollLimitEnabled ?? this.scrollLimitEnabled,
      scrollLimitMinutes: scrollLimitMinutes ?? this.scrollLimitMinutes,
    );
  }
}
