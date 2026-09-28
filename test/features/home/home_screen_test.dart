import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/core/ui/stat_value.dart';
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/home/home_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/settings/settings_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/fake_stats_repository.dart';
import '../../helpers/phone_viewport.dart';
import '../../helpers/themed_app.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      ...overrides,
    ],
    child: themedApp(
      home: child,
      routes: {
        '/settings': (_) => const Scaffold(body: Text('settings-stub')),
        '/permissions': (_) => const Scaffold(body: Text('permissions-stub')),
      },
    ),
  );
}

void main() {
  testWidgets('shows today\'s stats and a granted status card', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const HomeScreen(),
        overrides: [
          statsRepositoryProvider.overrideWithValue(
            FakeStatsRepository(
              const DailyStats(
                reelsBlockedCount: 4,
                feedSecondsToday: 300,
                feedBlockedCount: 1,
              ),
            ),
          ),
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Reels bloqueados hoje: 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tempo no Feed hoje: 5 de 20 min'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Saídas forçadas do Feed hoje: 1'),
      findsOneWidget,
    );
    expect(find.text('Proteções ativas'), findsOneWidget);
  });

  testWidgets('shows an action-needed card when a permission is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const HomeScreen(),
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(
              status: const PermissionStatus(
                accessibilityEnabled: false,
                batteryOptimizationIgnored: true,
                autostartAcknowledged: true,
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ação necessária'), findsOneWidget);
  });

  testWidgets('tapping the status card navigates to /permissions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const HomeScreen(),
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proteções ativas'));
    await tester.pumpAndSettle();

    expect(find.text('permissions-stub'), findsOneWidget);
  });

  testWidgets('re-fetches permissions and stats when the app resumes', (
    tester,
  ) async {
    final statsRepo = FakeStatsRepository(
      const DailyStats(
        reelsBlockedCount: 4,
        feedSecondsToday: 300,
        feedBlockedCount: 1,
      ),
    );
    final permissionsRepo = FakePermissionsRepository(
      status: const PermissionStatus(
        accessibilityEnabled: false,
        batteryOptimizationIgnored: true,
        autostartAcknowledged: true,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        const HomeScreen(),
        overrides: [
          statsRepositoryProvider.overrideWithValue(statsRepo),
          permissionsRepositoryProvider.overrideWithValue(permissionsRepo),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Reels bloqueados hoje: 4'), findsOneWidget);
    expect(find.text('Ação necessária'), findsOneWidget);

    // The world changes while the app is in the background.
    statsRepo.stats = const DailyStats(
      reelsBlockedCount: 9,
      feedSecondsToday: 600,
      feedBlockedCount: 2,
    );
    permissionsRepo.status = const PermissionStatus(
      accessibilityEnabled: true,
      batteryOptimizationIgnored: true,
      autostartAcknowledged: true,
    );
    await tester.pumpAndSettle();

    // Nothing re-fetches on a plain rebuild — still the old values.
    expect(find.bySemanticsLabel('Reels bloqueados hoje: 4'), findsOneWidget);
    expect(find.text('Ação necessária'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Reels bloqueados hoje: 9'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tempo no Feed hoje: 10 de 20 min'),
      findsOneWidget,
    );
    expect(find.text('Proteções ativas'), findsOneWidget);
    expect(find.text('Ação necessária'), findsNothing);
  });

  testWidgets('stats are listed one below the other, even with room to spare', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const HomeScreen(),
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
          permissionsRepositoryProvider.overrideWithValue(
            FakePermissionsRepository(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final tops = find
        .byType(StatValue)
        .evaluate()
        .map((e) => tester.getTopLeft(find.byWidget(e.widget)))
        .toList();
    expect(tops, hasLength(3));
    expect(tops.map((o) => o.dx).toSet(), hasLength(1)); // same column
    expect(tops[0].dy < tops[1].dy && tops[1].dy < tops[2].dy, isTrue);
  });

  group('layout fits the screen', () {
    for (final viewport in phoneViewports) {
      testWidgets('on $viewport', (tester) async {
        applyViewport(tester, viewport);
        await tester.pumpWidget(
          _wrap(
            const HomeScreen(),
            overrides: [
              statsRepositoryProvider.overrideWithValue(
                FakeStatsRepository(
                  const DailyStats(
                    reelsBlockedCount: 128,
                    feedSecondsToday: 5400,
                    feedBlockedCount: 3,
                  ),
                ),
              ),
              permissionsRepositoryProvider.overrideWithValue(
                FakePermissionsRepository(
                  status: const PermissionStatus(
                    accessibilityEnabled: false,
                    batteryOptimizationIgnored: true,
                    autostartAcknowledged: true,
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await expectContentFitsScreen(tester, viewport);
      });
    }
  });
}
