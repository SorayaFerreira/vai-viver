class PermissionStatus {
  const PermissionStatus({
    required this.accessibilityEnabled,
    this.accessibilityRunning = true,
    required this.batteryOptimizationIgnored,
    required this.autostartAcknowledged,
  });

  final bool accessibilityEnabled;

  /// Whether Android actually has the service connected. The native side
  /// always reports it; the default only keeps older call sites short.
  final bool accessibilityRunning;
  final bool batteryOptimizationIgnored;
  final bool autostartAcknowledged;

  /// Turned on in Settings, but not running — what Android calls
  /// "malfunctioning" (e.g. MIUI killed the app when swiped from recents).
  bool get accessibilityStalled =>
      accessibilityEnabled && !accessibilityRunning;

  bool get allGranted =>
      accessibilityEnabled &&
      accessibilityRunning &&
      batteryOptimizationIgnored &&
      autostartAcknowledged;
}
