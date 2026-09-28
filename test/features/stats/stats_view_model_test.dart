import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_stats_repository.dart';

void main() {
  test('refresh re-reads stats from the repository', () async {
    final fakeRepo = FakeStatsRepository(
      const DailyStats(
        reelsBlockedCount: 1,
        feedSecondsToday: 30,
        feedBlockedCount: 0,
      ),
    );
    final container = ProviderContainer(
      overrides: [statsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(statsViewModelProvider.future);
    fakeRepo.stats = const DailyStats(
      reelsBlockedCount: 3,
      feedSecondsToday: 90,
      feedBlockedCount: 0,
    );
    await container.read(statsViewModelProvider.notifier).refresh();

    expect(container.read(statsViewModelProvider).value!.reelsBlockedCount, 3);
  });

  test('refresh surfaces a channel failure as AsyncError instead of hanging in loading', () async {
    final fakeRepo = FakeStatsRepository();
    final container = ProviderContainer(
      overrides: [statsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(statsViewModelProvider.future);
    fakeRepo.error = PlatformException(code: 'unavailable');
    await container.read(statsViewModelProvider.notifier).refresh();

    final state = container.read(statsViewModelProvider);
    expect(state.isLoading, false);
    expect(state.error, isA<PlatformException>());
  });
}
