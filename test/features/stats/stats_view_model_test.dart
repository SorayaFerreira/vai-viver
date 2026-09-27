import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaiviver/domain/models/daily_stats.dart';
import 'package:vaiviver/features/stats/stats_view_model.dart';

import '../../fakes/fake_stats_repository.dart';

void main() {
  test('refresh re-reads stats from the repository', () async {
    final fakeRepo = FakeStatsRepository(const DailyStats(reelsBlockedCount: 1, scrollSecondsSaved: 30));
    final container = ProviderContainer(
      overrides: [statsRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    await container.read(statsViewModelProvider.future);
    fakeRepo.stats = const DailyStats(reelsBlockedCount: 3, scrollSecondsSaved: 90);
    await container.read(statsViewModelProvider.notifier).refresh();

    expect(container.read(statsViewModelProvider).value!.reelsBlockedCount, 3);
  });
}
