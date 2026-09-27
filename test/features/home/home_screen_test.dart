import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/domain/models/permission_status.dart';
import 'package:vaiviver/features/home/home_screen.dart';
import 'package:vaiviver/features/permissions/permissions_view_model.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_permissions_repository.dart';
import '../../fakes/fake_stats_repository.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
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
    await tester.pumpWidget(_wrap(
      const HomeScreen(),
      overrides: [
        statsRepositoryProvider.overrideWithValue(
          FakeStatsRepository(const DailyStats(reelsBlockedCount: 4, scrollSecondsSaved: 300)),
        ),
        permissionsRepositoryProvider.overrideWithValue(FakePermissionsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reels bloqueados hoje: 4'), findsOneWidget);
    expect(find.text('Minutos de scroll evitados hoje: 5 min'), findsOneWidget);
    expect(find.text('Proteções ativas'), findsOneWidget);
  });

  testWidgets('shows an action-needed card when a permission is missing', (tester) async {
    await tester.pumpWidget(_wrap(
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
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ação necessária'), findsOneWidget);
  });

  testWidgets('tapping the status card navigates to /permissions', (tester) async {
    await tester.pumpWidget(_wrap(
      const HomeScreen(),
      overrides: [
        statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
        permissionsRepositoryProvider.overrideWithValue(FakePermissionsRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proteções ativas'));
    await tester.pumpAndSettle();

    expect(find.text('permissions-stub'), findsOneWidget);
  });
}
