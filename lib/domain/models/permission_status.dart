class PermissionStatus {
  const PermissionStatus({
    required this.accessibilityEnabled,
    required this.batteryOptimizationIgnored,
    required this.autostartAcknowledged,
  });

  final bool accessibilityEnabled;
  final bool batteryOptimizationIgnored;
  final bool autostartAcknowledged;

  bool get allGranted =>
      accessibilityEnabled && batteryOptimizationIgnored && autostartAcknowledged;
}
