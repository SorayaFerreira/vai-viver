import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/ui/ambient_background.dart';
import 'package:vaiviver/core/ui/app_screen.dart';

import '../../helpers/themed_app.dart';

void main() {
  testWidgets('shows an AppBar only when titled', (tester) async {
    await tester.pumpWidget(
      themedApp(
        home: const AppScreen(title: 'Título', body: SizedBox()),
      ),
    );
    expect(find.widgetWithText(AppBar, 'Título'), findsOneWidget);

    await tester.pumpWidget(themedApp(home: const AppScreen(body: SizedBox())));
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('paints the ambient background behind a transparent Scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(themedApp(home: const AppScreen(body: SizedBox())));

    expect(find.byType(AmbientBackground), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.transparent,
    );
  });

  testWidgets('status bar icons follow the theme', (tester) async {
    await tester.pumpWidget(themedApp(home: const AppScreen(body: SizedBox())));
    final lightRegion = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(lightRegion.value.statusBarIconBrightness, Brightness.dark);

    await tester.pumpWidget(
      themedApp(
        themeMode: ThemeMode.dark,
        home: const AppScreen(body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    final darkRegion = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(darkRegion.value.statusBarIconBrightness, Brightness.light);
  });
}
