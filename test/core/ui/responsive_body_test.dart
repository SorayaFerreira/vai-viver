import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/ui/app_screen.dart';
import 'package:vaiviver/core/ui/responsive_body.dart';

import '../../helpers/phone_viewport.dart';
import '../../helpers/themed_app.dart';

final _longText = List.filled(
  12,
  'Necessária para detectar Reels e medir a rolagem do Feed.',
).join(' ');

void main() {
  group('keeps content on screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('long content + pinned action on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          themedApp(
            home: AppScreen(
              body: ResponsiveBody(
                bottomAction: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Próximo'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const Text('Acessibilidade'), Text(_longText)],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });

      testWidgets('centered short content on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          themedApp(
            home: AppScreen(
              body: ResponsiveBody(
                bottomAction: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Próximo'),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bem-vinda ao VaiViver'),
                    Text(
                      'O VaiViver bloqueia a aba Reels do Instagram e limita '
                      'quanto tempo você rola o Feed.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });

  testWidgets('content spans the width, capped at maxContentWidth', (
    tester,
  ) async {
    Future<double> contentWidthOn(PhoneViewport viewport) async {
      applyViewport(tester, viewport);
      await tester.pumpWidget(
        themedApp(
          home: const AppScreen(
            body: ResponsiveBody(
              child: SizedBox(key: Key('content'), height: 10),
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(const Key('content'))).width;
    }

    // Portrait: full width minus 16dp gutters on each side.
    expect(await contentWidthOn(phoneViewports.first), 393 - 32);
    // Landscape: capped so lines stay readable.
    expect(
      await contentWidthOn(phoneViewports.last),
      ResponsiveBody.maxContentWidth,
    );
  });

  testWidgets('short content is centered in the safe area', (tester) async {
    applyViewport(tester, phoneViewports.first);
    await tester.pumpWidget(
      themedApp(
        home: const AppScreen(body: ResponsiveBody(child: Text('meio'))),
      ),
    );

    // Safe area 36..849; minus the 8/24 scroll padding -> 44..825.
    expect(tester.getCenter(find.text('meio')).dy, closeTo(434.5, 1));
  });

  testWidgets('a short card is vertically centered and keeps the full width', (
    tester,
  ) async {
    applyViewport(tester, phoneViewports.first);
    await tester.pumpWidget(
      themedApp(
        home: const AppScreen(
          body: ResponsiveBody(child: SizedBox(key: Key('card'), height: 100)),
        ),
      ),
    );

    final card = tester.getRect(find.byKey(const Key('card')));
    // Same content box as above (44..825), so the centre is at 434.5.
    expect(card.center.dy, closeTo(434.5, 1));
    expect(card.width, 393 - 32);
  });
}
