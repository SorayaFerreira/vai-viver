import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/theme/app_palette.dart';
import 'package:vaiviver/core/theme/vaiviver_tokens.dart';
import 'package:vaiviver/core/ui/ambient_background.dart';
import 'package:vaiviver/core/ui/glass_card.dart';
import 'package:vaiviver/core/ui/stat_value.dart';
import 'package:vaiviver/core/ui/status_pill.dart';
import 'package:vaiviver/core/ui/terminal_label.dart';

import '../../helpers/themed_app.dart';

Widget _host(Widget child) => themedApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets(
    'AmbientBackground paints the theme background behind its child',
    (tester) async {
      for (final (mode, palette) in [
        (ThemeMode.light, AppPalette.light),
        (ThemeMode.dark, AppPalette.dark),
      ]) {
        await tester.pumpWidget(
          themedApp(
            themeMode: mode,
            home: const AmbientBackground(child: Text('conteúdo')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('conteúdo'), findsOneWidget);
        final background = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(AmbientBackground),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (background.decoration as BoxDecoration).color,
          palette.background,
        );
      }
    },
  );

  testWidgets('GlassCard blurs what is behind it', (tester) async {
    await tester.pumpWidget(_host(const GlassCard(child: Text('vidro'))));

    final filter = tester.widget<BackdropFilter>(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(BackdropFilter),
      ),
    );
    expect(filter.filter, isA<ImageFilter>());
    expect(find.text('vidro'), findsOneWidget);
  });

  testWidgets('GlassCard is tappable only when onTap is set', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassCard(onTap: () => taps++, child: const Text('tocável')),
            const GlassCard(child: Text('estático')),
          ],
        ),
      ),
    );

    await tester.tap(find.text('tocável'));
    expect(taps, 1);

    final staticInkWell = tester.widget<InkWell>(
      find.ancestor(of: find.text('estático'), matching: find.byType(InkWell)),
    );
    expect(staticInkWell.onTap, isNull);
  });

  testWidgets(
    'TerminalLabel renders a prompt and is hidden from screen readers',
    (tester) async {
      await tester.pumpWidget(_host(const TerminalLabel('status')));

      expect(find.text('~/vaiviver \$ status'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('vaiviver')), findsNothing);
    },
  );

  testWidgets('StatusPill uses the success/warning token colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusPill(label: 'ativada', tone: PillTone.success),
            StatusPill(label: 'pendente', tone: PillTone.warning),
          ],
        ),
      ),
    );

    final tokens = VaiViverTokens.fromPalette(AppPalette.light);
    Color? textColor(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(textColor('ativada'), tokens.success);
    expect(textColor('pendente'), tokens.warning);
  });

  testWidgets('StatValue reads as one sentence and paints a gradient number', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const StatValue(
          value: '5',
          unit: 'min',
          label: 'Minutos de scroll evitados hoje',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Minutos de scroll evitados hoje: 5 min'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(StatValue),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
  });
}
