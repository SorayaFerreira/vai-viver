import 'package:flutter/material.dart';
import 'package:vaiviver/core/theme/app_theme.dart';

/// A MaterialApp with the real VaiViver theme. Every widget test that renders
/// app UI must use it: the design-system widgets read VaiViverTokens from the
/// theme and assert it is there.
Widget themedApp({
  required Widget home,
  Map<String, WidgetBuilder> routes = const {},
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: home,
    routes: routes,
  );
}
