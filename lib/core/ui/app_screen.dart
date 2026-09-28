import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ambient_background.dart';

/// Chrome shared by every screen: ambient background behind a transparent
/// Scaffold, an optional AppBar and system bar icons that match the theme.
/// Put a ResponsiveBody in [body] so the content stays on screen.
class AppScreen extends StatelessWidget {
  const AppScreen({super.key, required this.body, this.title, this.actions});

  final Widget body;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(Theme.of(context).brightness),
      child: AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: title == null
              ? null
              : AppBar(title: Text(title!), actions: actions),
          body: body,
        ),
      ),
    );
  }
}
